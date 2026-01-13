module vault::vault {
    use std::signer;
    use std::string::{Self, String};
    use std::option;
    use aptos_std::math64;
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::primary_fungible_store;

    use decibel_dex::perp_engine;
    use decibel_dex::perp_market::{Self, PerpMarket};
    use decibel_dex::dex_accounts;
    use aptos_experimental::order_book_types;
    use decibel_dex::dex_accounts_vault_extension;
    use decibel_dex::vault;
    use decibel_dex::vault_api;
    use std::vector;

    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_VAULT_NOT_FOUND: u64 = 2;
    const E_NOT_DELEGATEE: u64 = 3;

    const DECIBEL_SEED: vector<u8> = b"GlobalVaultConfig";

    /// Helper function: Làm tròn price theo tick size
    fun round_price_to_tick(price: u64, tick_size: u64, round_up: bool): u64 {
    // Tính số tick nguyên
    let num_ticks = price / tick_size;
    let remainder = price % tick_size;
    
    if (remainder == 0) {
        // Đã chia hết
        price
    } else if (round_up) {
        // Làm tròn lên: (num_ticks + 1) * tick_size
        (num_ticks + 1) * tick_size
    } else {
        // Làm tròn xuống: num_ticks * tick_size
        num_ticks * tick_size
    }
}

    /// Helper function: Làm tròn size theo lot size
    fun round_size_to_lot(size: u64, lot_size: u64): u64 {
        let remainder = size % lot_size;
        if (remainder == 0) { size }
        else {
            // Luôn làm tròn xuống để đảm bảo không vượt quá collateral
            size - remainder
        }
    }

    fun is_delegatee(self: &Vault, addr: address): bool {
        self.delegator_trading == addr
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Vault has key {
        extend_ref: ExtendRef,
        store: Object<FungibleStore>,
        asset_metadata: Object<Metadata>,
        perp_market: Object<PerpMarket>,
        subaccount: Object<dex_accounts::Subaccount>,
        vault_name: String,
        decibel_vault: Object<decibel_dex::vault::Vault>,
        delegator_trading: address,
        leverage: u8
    }

    public entry fun init_vault(
        owner: &signer,
        asset_metadata: Object<Metadata>,
        vault_name: String,
        perp_market: Object<PerpMarket>,
        delegatee: address,
        leverage: u8
    ) {
        let constructor_ref =
            object::create_named_object(owner, *string::bytes(&vault_name));
        let object_signer = object::generate_signer(&constructor_ref);
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        let store = fungible_asset::create_store(&constructor_ref, asset_metadata);

        let vault_addr = signer::address_of(&object_signer);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);

        // Configure cho subaccount của vault wrapper
        dex_accounts::configure_user_settings_for_market(
            &object_signer,
            subaccount_addr,
            perp_market,
            true,
            leverage
        );

        // Tạo Decibel Vault
        vault_api::create_and_fund_vault(
            &object_signer,
            option::none(),
            asset_metadata,
            vault_name,
            string::utf8(b""),
            vector::empty(),
            string::utf8(b""),
            string::utf8(b""),
            string::utf8(b""),
            0,
            0,
            0,
            0,
            false,
            false
        );

        let decibel_vault =
            object::address_to_object<vault::Vault>(decibel_vault_address(vault_name));

        // Delegate quyền cho vault_addr ĐỂ NÓ CÓ THỂ CONFIGURE
        vault::delegate_dex_actions_to(
            &object_signer,
            decibel_vault,
            vault_addr,  // ← Delegate cho chính vault_addr
            option::none()
        );

        // BÂY GIỜ vault_addr có quyền configure rồi!
        dex_accounts::configure_user_settings_for_market(
            &object_signer,  // object_signer có address = vault_addr
            vault::get_vault_portfolio_subaccounts(decibel_vault)[0],
            perp_market,
            true,
            leverage
        );

        // Delegate thêm cho delegatee nếu cần
        if (delegatee != vault_addr) {
            vault::delegate_dex_actions_to(
                &object_signer,
                decibel_vault,
                delegatee,
                option::none()
            );
        };

        // Change admin về subaccount
        vault::change_admin(&object_signer, decibel_vault, subaccount_addr);
        
        move_to(
            &object_signer,
            Vault {
                extend_ref,
                store,
                asset_metadata,
                perp_market,
                subaccount: dex_accounts::primary_subaccount_object(vault_addr),
                vault_name,
                decibel_vault,
                delegator_trading: delegatee,
                leverage
            }
        );
    }

    public entry fun deposit(
        user: &signer,
        vault: Object<Vault>,
        amount: u64
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);

        let fa = primary_fungible_store::withdraw(
            user, vault_data.asset_metadata, amount
        );
        fungible_asset::deposit(vault_data.store, fa);

        // Deposit vào subaccount
        let fa_to_subaccount =
            fungible_asset::withdraw(&vault_signer, vault_data.store, amount);
        let subaccount_addr = object::object_address(&vault_data.subaccount);
        dex_accounts::deposit_funds_to_subaccount_at(
            &vault_signer,
            subaccount_addr,
            fa_to_subaccount
        );

        //Deposit vào Decibel Vault
        dex_accounts_vault_extension::contribute_to_vault(
            &vault_signer,
            vault_data.subaccount,
            decibel_vault_address(vault_data.vault_name),
            vault_data.asset_metadata,
            amount
        );
    }

    public entry fun withdraw(
        user: &signer,
        vault: Object<Vault>,
        amount: u64
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        let balance = vault::get_vault_net_asset_value(vault_data.decibel_vault);
        assert!(amount <= balance, E_INSUFFICIENT_BALANCE);
        // Withdraw từ Decibel Vault
        dex_accounts_vault_extension::redeem_from_vault(
            &vault_signer,
            vault_data.subaccount,
            decibel_vault_address(vault_data.vault_name),
            amount
        );

        // Withdraw từ subaccount về vault store
        let fa_from_subaccount =
            dex_accounts::withdraw_onchain_account_funds_from_subaccount(
                &vault_data.extend_ref,
                vault_data.subaccount,
                vault_data.asset_metadata,
                amount
            );
        fungible_asset::deposit(vault_data.store, fa_from_subaccount);

        // Withdraw từ vault store về user
        let fa_to_user =
            fungible_asset::withdraw(&vault_signer, vault_data.store, amount);
        fungible_asset::deposit(
            primary_fungible_store::ensure_primary_store_exists(signer::address_of(user), vault_data.asset_metadata),
            fa_to_user
        );
    }

    public entry fun long_position(
        sender: &signer,
        vault: Object<Vault>,
        amount: u64
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        assert!(vault_data.is_delegatee(signer::address_of(sender)), E_NOT_DELEGATEE);

        let balance = vault::get_vault_net_asset_value(vault_data.decibel_vault);
        if (amount > balance) {
            amount = balance;
        };

        let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
        let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);

        let price_with_slippage = mark_price + (mark_price / 100);

        let execution_price = round_price_to_tick(price_with_slippage, tick_size, true);
        assert!(execution_price % tick_size == 0, 9999);

        let size_decimals = perp_engine::market_sz_decimals(vault_data.perp_market);
        let collateral_value = (amount as u128) * (vault_data.leverage as u128);
        let size_scale = math64::pow(10, (size_decimals as u64));
        let size_raw = (collateral_value * (size_scale as u128))
            / (execution_price as u128);
        let size = (size_raw as u64);

        let lot_size = perp_engine::market_lot_size(vault_data.perp_market);
        let size = round_size_to_lot(size, lot_size);
        let min_size = perp_engine::market_min_size(vault_data.perp_market);
        assert!(size >= min_size, 999);
        assert!(size % lot_size == 0, 998);

        let decibel_subaccount_addr = vault::get_vault_portfolio_subaccounts(vault_data.decibel_vault)[0];
        let subaccount_obj = object::address_to_object<dex_accounts::Subaccount>(decibel_subaccount_addr);
        let _order_id =
            dex_accounts::place_order_to_subaccount_method(
                sender,
                subaccount_obj,
                vault_data.perp_market,
                execution_price,
                size,
                true,
                order_book_types::time_in_force_from_index(2),
                false,
                option::none<String>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<address>(),
                option::none<u64>()
            );
    }

    public entry fun short_position(
        sender: &signer,
        vault: Object<Vault>,
        amount: u64
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        assert!(vault_data.is_delegatee(signer::address_of(sender)), E_NOT_DELEGATEE);

        let balance = vault::get_vault_net_asset_value(vault_data.decibel_vault);
        if (amount > balance) {
            amount = balance;
        };

        // Lấy mark price và tick size
        let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
        let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);

        // Tính price với slippage 1% (giá thấp hơn cho short)
        let price_with_slippage = mark_price - (mark_price / 100);

        // Làm tròn xuống tick size cho short
        let execution_price = round_price_to_tick(price_with_slippage, tick_size, false);
        assert!(execution_price % tick_size == 0, 9999);

        // Tính size
        let size_decimals = perp_engine::market_sz_decimals(vault_data.perp_market);
        let collateral_value = (amount as u128) * (vault_data.leverage as u128);
        let size_scale = math64::pow(10, (size_decimals as u64));
        let size_raw = (collateral_value * (size_scale as u128))
            / (execution_price as u128);
        let size = (size_raw as u64);

        // Làm tròn size
        let lot_size = perp_engine::market_lot_size(vault_data.perp_market);
        let size = round_size_to_lot(size, lot_size);
        let min_size = perp_engine::market_min_size(vault_data.perp_market);
        assert!(size >= min_size, 999);
        assert!(size % lot_size == 0, 998);

        // Place order - lấy trực tiếp từ vault_data
        let decibel_subaccount_addr = vault::get_vault_portfolio_subaccounts(vault_data.decibel_vault)[0];
        let subaccount_obj = object::address_to_object<dex_accounts::Subaccount>(decibel_subaccount_addr);
        let _order_id =
            dex_accounts::place_order_to_subaccount_method(
                sender,
                subaccount_obj,
                vault_data.perp_market,
                execution_price,
                size,
                false, // is_bid = false (short/sell)
                order_book_types::time_in_force_from_index(2),
                false,
                option::none<String>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<address>(),
                option::none<u64>()
            );
    }

    public entry fun close_position(
        sender: &signer, 
        vault: Object<Vault>
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        assert!(vault_data.is_delegatee(signer::address_of(sender)), E_NOT_DELEGATEE);

        let decibel_subaccount_addr = vault::get_vault_portfolio_subaccounts(vault_data.decibel_vault)[0];
        let subaccount_obj = object::address_to_object<dex_accounts::Subaccount>(decibel_subaccount_addr);
        
        let position_size =
            perp_engine::get_position_size(decibel_subaccount_addr, vault_data.perp_market);
        let is_long =
            perp_engine::get_position_is_long(decibel_subaccount_addr, vault_data.perp_market);

        if (position_size > 0) {
            let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
            let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);

            let price_with_slippage = if (is_long) {
                mark_price - (mark_price / 100)  // -1% slippage
            } else {
                mark_price + (mark_price / 100)
            };

            let execution_price = round_price_to_tick(price_with_slippage, tick_size, !is_long);
            // DEBUG: Add assertions
            assert!(execution_price > 0, 8881);
            assert!(execution_price % tick_size == 0, 8882);

            let _order_id =
                dex_accounts::place_order_to_subaccount_method(
                    sender,
                    subaccount_obj,
                    vault_data.perp_market,
                    execution_price,
                    position_size,
                    !is_long,
                    order_book_types::time_in_force_from_index(2),
                    true,
                    option::none<String>(),
                    option::none<u64>(),
                    option::none<u64>(),
                    option::none<u64>(),
                    option::none<u64>(),
                    option::none<u64>(),
                    option::none<address>(),
                    option::none<u64>()
                );
        }
    }

    public entry fun test_place_order(
        sender: &signer,
        vault: Object<Vault>,
        size: u64,
        price: u64,
        is_bid: bool
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        assert!(vault_data.is_delegatee(signer::address_of(sender)), E_NOT_DELEGATEE);
        
        // Lấy decibel subaccount trực tiếp từ vault_data
        let decibel_subaccount_addr = vault::get_vault_portfolio_subaccounts(vault_data.decibel_vault)[0];
        let subaccount_obj = object::address_to_object<dex_accounts::Subaccount>(decibel_subaccount_addr);
        let _order_id =
            dex_accounts::place_order_to_subaccount_method(
                sender,
                subaccount_obj,
                vault_data.perp_market,
                price,
                size,
                is_bid,
                order_book_types::time_in_force_from_index(2),
                false,
                option::none<String>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<address>(),
                option::none<u64>()
            );
    }

    // ========== VIEW FUNCTIONS ==========

    #[view]
    public fun get_subaccount(vault: Object<Vault>): Object<dex_accounts::Subaccount> {
        let vault_addr = object::object_address(&vault);
        dex_accounts::primary_subaccount_object(vault_addr)
    }

    #[view]
    public fun get_decibel_vault_net_asset_value(vault: Object<Vault>): u64 acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        vault::get_vault_net_asset_value(vault_data.decibel_vault)
    }

    #[view]
    public fun get_decibel_vault_subaccount(vault: Object<Vault>): Object<dex_accounts::Subaccount> acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let account = vault::get_vault_portfolio_subaccounts(vault_data.decibel_vault)[0];
        object::address_to_object<dex_accounts::Subaccount>(account)
    }

    #[view]
    public fun decibel_vault_address(name: String): address {
        let decibel_sounrce = object::create_object_address(&@decibel_dex, DECIBEL_SEED);
        object::create_object_address(&decibel_sounrce, *string::bytes(&name))
    }

    #[view]
    public fun get_balance(vault: Object<Vault>): u64 acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        fungible_asset::balance(vault_data.store)
    }

    #[view]
    public fun get_subaccount_balance(vault: Object<Vault>): u64 {
        let vault_addr = object::object_address(&vault);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        perp_engine::get_account_balance_fungible(subaccount_addr)
    }

    #[view]
    public fun get_total_balance(vault: Object<Vault>): u64 acquires Vault {
        let vault_store_balance = get_balance(vault);
        let subaccount_balance = get_subaccount_balance(vault);
        vault_store_balance + subaccount_balance
    }

    #[view]
    public fun get_max_withdrawable(vault: Object<Vault>): u64 acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        perp_engine::max_allowed_withdraw_fungible_amount(
            subaccount_addr, vault_data.asset_metadata
        )
    }

    #[view]
    public fun get_asset_metadata(vault: Object<Vault>): Object<Metadata> acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        vault_data.asset_metadata
    }

    #[view]
    public fun is_owner(vault: Object<Vault>, addr: address): bool {
        object::is_owner(vault, addr)
    }

    #[view]
    public fun get_leverage(vault: Object<Vault>): u8 acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        vault_data.leverage
    }

    #[view]
    public fun get_perp_market(vault: Object<Vault>): Object<PerpMarket> acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        vault_data.perp_market
    }

    #[view]
    public fun get_position_size(vault: Object<Vault>): u64 acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        perp_engine::get_position_size(subaccount_addr, vault_data.perp_market)
    }

    #[view]
    public fun get_position_is_long(vault: Object<Vault>): bool acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        perp_engine::get_position_is_long(subaccount_addr, vault_data.perp_market)
    }

    #[view]
    public fun debug_close_position_info(vault: Object<Vault>): (u64, u64, u64, bool) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let decibel_subaccount_addr = vault::get_vault_portfolio_subaccounts(vault_data.decibel_vault)[0];
        
        let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);
        let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
        let position_size = perp_engine::get_position_size(decibel_subaccount_addr, vault_data.perp_market);
        let is_long = perp_engine::get_position_is_long(decibel_subaccount_addr, vault_data.perp_market);
        
        (tick_size, mark_price, position_size, is_long)
    }
}
