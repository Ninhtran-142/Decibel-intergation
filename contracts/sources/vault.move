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
    
    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_VAULT_NOT_FOUND: u64 = 2;

    /// Helper function: Làm tròn price theo tick size
    fun round_price_to_tick(price: u64, tick_size: u64, round_up: bool): u64 {
        let remainder = price % tick_size;
        if (remainder == 0) {
            // Đã chia hết, không cần làm tròn
            price
        } else if (round_up) {
            // Làm tròn lên
            price + (tick_size - remainder)
        } else {
            // Làm tròn xuống
            price - remainder
        }
    }

    /// Helper function: Làm tròn size theo lot size
    fun round_size_to_lot(size: u64, lot_size: u64): u64 {
        let remainder = size % lot_size;
        if (remainder == 0) {
            size
        } else {
            // Luôn làm tròn xuống để đảm bảo không vượt quá collateral
            size - remainder
        }
    }
 
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Vault has key {
        extend_ref: ExtendRef,
        store: Object<FungibleStore>,
        asset_metadata: Object<Metadata>,
        perp_market: Object<PerpMarket>,
        leverage: u8,
    }

    public entry fun init_vault(
        owner: &signer,
        asset_metadata: Object<Metadata>,
        vault_name: String,
        perp_market: Object<PerpMarket>,
        leverage: u8,
    ) {
        let constructor_ref = object::create_named_object(owner, *string::bytes(&vault_name));
        let object_signer = object::generate_signer(&constructor_ref);
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        let store = fungible_asset::create_store(&constructor_ref, asset_metadata);
        
        // Tạo và configure primary subaccount
        let vault_addr = signer::address_of(&object_signer);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        
        dex_accounts::configure_user_settings_for_market(
            &object_signer,
            subaccount_addr,
            perp_market,
            true,
            leverage
        );
        
        move_to(&object_signer, Vault {
            extend_ref,
            store,
            asset_metadata,
            perp_market,
            leverage,
        });
    }

    public entry fun deposit(
        user: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let fa = primary_fungible_store::withdraw(user, vault_data.asset_metadata, amount);
        fungible_asset::deposit(vault_data.store, fa);
        
        // Deposit vào subaccount
        let fa_to_subaccount = fungible_asset::withdraw(&vault_signer, vault_data.store, amount);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        dex_accounts::deposit_funds_to_subaccount_at(
            &vault_signer,
            subaccount_addr,
            fa_to_subaccount
        );
    }

    public entry fun withdraw(
        user: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);

        // Check available balance trong subaccount
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        let max_withdrawable = perp_engine::max_allowed_withdraw_fungible_amount(
            subaccount_addr, 
            vault_data.asset_metadata
        );
        
        // Tính số tiền có thể withdraw
        let withdraw_from_subaccount = if (amount <= max_withdrawable) {
            amount
        } else {
            max_withdrawable
        };

        // Withdraw từ subaccount nếu có balance
        if (withdraw_from_subaccount > 0) {
            let subaccount_obj = get_subaccount(vault);
            let withdrawn_fa = dex_accounts::withdraw_onchain_account_funds_from_subaccount(
                &vault_data.extend_ref,
                subaccount_obj,
                vault_data.asset_metadata,
                withdraw_from_subaccount
            );
            fungible_asset::deposit(vault_data.store, withdrawn_fa);
        };
        
        // Check vault store balance
        let vault_store_balance = fungible_asset::balance(vault_data.store);
        
        // Tính số tiền thực tế có thể withdraw
        let final_withdraw_amount = if (amount <= vault_store_balance) {
            amount
        } else {
            vault_store_balance
        };
        
        assert!(final_withdraw_amount > 0, E_INSUFFICIENT_BALANCE);
        
        // Withdraw từ vault store ra user
        let fa = fungible_asset::withdraw(&vault_signer, vault_data.store, final_withdraw_amount);
        primary_fungible_store::deposit(signer::address_of(user), fa);
    }

    public entry fun long_position(
        sender: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);

        // Lấy mark price và tick size
        let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
        let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);
        
        // Tính price với slippage 1%
        let price_with_slippage = mark_price + (mark_price / 100);
        
        // Làm tròn lên tick size
        let execution_price = round_price_to_tick(price_with_slippage, tick_size, true);
        assert!(execution_price % tick_size == 0, 9999);
        // Tính size
        let size_decimals = perp_engine::market_sz_decimals(vault_data.perp_market);
        let collateral_value = (amount as u128) * (vault_data.leverage as u128);
        let size_scale = math64::pow(10, (size_decimals as u64));
        let size_raw = (collateral_value * (size_scale as u128)) / (execution_price as u128);
        let size = (size_raw as u64);

        // Làm tròn size
        let lot_size = perp_engine::market_lot_size(vault_data.perp_market);
        let size = round_size_to_lot(size, lot_size);
        let min_size = perp_engine::market_min_size(vault_data.perp_market);
        assert!(size >= min_size, 999);
        assert!(size % lot_size == 0, 998);
        // Place order
        let subaccount_obj = get_subaccount(vault);
        let _order_id = dex_accounts::place_order_to_subaccount_method(
            &vault_signer,
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
            option::none<u64>(),
        );
    }

    public entry fun test_place_order(
        sender: &signer,
        vault: Object<Vault>,
        size: u64,
        price: u64,
        is_bid: bool,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let subaccount_obj = get_subaccount(vault);
        let _order_id = dex_accounts::place_order_to_subaccount_method(
            &vault_signer,
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
            option::none<u64>(),
        );
    }

    public entry fun close_position(
        sender: &signer,
        vault: Object<Vault>,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        let position_size = perp_engine::get_position_size(subaccount_addr, vault_data.perp_market);
        let is_long = perp_engine::get_position_is_long(subaccount_addr, vault_data.perp_market);
        
        if (position_size > 0) {
            let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);
            let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
            
            // Làm tròn mark price trước
            let rounded_mark = round_price_to_tick(mark_price, tick_size, !is_long);
            
            // Tính slippage
            let slippage = rounded_mark * 5 / 1000;
            let slippage = round_price_to_tick(slippage, tick_size, true);
            
            // Execution price
            let execution_price = if (is_long) {
                // Close long = sell, giá thấp hơn
                if (rounded_mark > slippage) {
                    rounded_mark - slippage
                } else {
                    rounded_mark
                }
            } else {
                // Close short = buy, giá cao hơn
                rounded_mark + slippage
            };

            let subaccount_obj = get_subaccount(vault);
            let _order_id = dex_accounts::place_order_to_subaccount_method(
                &vault_signer,
                subaccount_obj,
                vault_data.perp_market,
                execution_price,
                position_size,
                !is_long, // is_bid = opposite of current position
                order_book_types::time_in_force_from_index(2),
                false,
                option::none<String>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::some<u64>(position_size), // reduce_only_size
                option::none<address>(),
                option::none<u64>(),
            );
        }
    }

    public entry fun short_position(
        sender: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        // Check vault store balance
        let vault_store_balance = fungible_asset::balance(vault_data.store);
        let deposit_amount = if (amount <= vault_store_balance) {
            amount
        } else {
            vault_store_balance
        };
        
        assert!(deposit_amount > 0, E_INSUFFICIENT_BALANCE);
        
        // Withdraw và deposit vào subaccount
        let fa = fungible_asset::withdraw(&vault_signer, vault_data.store, deposit_amount);
        let subaccount_addr = dex_accounts::primary_subaccount(vault_addr);
        dex_accounts::deposit_funds_to_subaccount_at(
            &vault_signer,
            subaccount_addr,
            fa
        );

        // Lấy tick size và mark price
        let tick_size = perp_engine::market_ticker_size(vault_data.perp_market);
        let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
        
        // Làm tròn mark price trước (round down cho sell)
        let rounded_mark = round_price_to_tick(mark_price, tick_size, false);
        
        // Tính slippage 0.5%
        let slippage = rounded_mark * 5 / 1000;
        let slippage = round_price_to_tick(slippage, tick_size, true);
        
        // Execution price (thấp hơn mark cho short)
        let execution_price = if (rounded_mark > slippage) {
            rounded_mark - slippage
        } else {
            rounded_mark
        };

        // Tính size với deposit_amount thực tế
        let size_decimals = perp_engine::market_sz_decimals(vault_data.perp_market);
        let collateral_value = (deposit_amount as u128) * (vault_data.leverage as u128);
        let size_scale = math64::pow(10, (size_decimals as u64));
        let size_raw = (collateral_value * (size_scale as u128)) / (execution_price as u128);
        let size = (size_raw as u64);
        
        // Làm tròn size theo lot size
        let lot_size = perp_engine::market_lot_size(vault_data.perp_market);
        let size = round_size_to_lot(size, lot_size);
        
        // Place order qua subaccount
        let subaccount_obj = get_subaccount(vault);
        let _order_id = dex_accounts::place_order_to_subaccount_method(
            &vault_signer,
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
            option::none<u64>(),
        );
    }

    // ========== VIEW FUNCTIONS ==========

    #[view]
    public fun get_subaccount(vault: Object<Vault>): Object<dex_accounts::Subaccount> {
        let vault_addr = object::object_address(&vault);
        dex_accounts::primary_subaccount_object(vault_addr)
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
        perp_engine::max_allowed_withdraw_fungible_amount(subaccount_addr, vault_data.asset_metadata)
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
}