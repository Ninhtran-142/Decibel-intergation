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
    use decibel_dex::builder_code_registry::BuilderCode;
    
    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_VAULT_NOT_FOUND: u64 = 2;
 
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
        
        perp_engine::configure_user_settings_for_market(&object_signer, perp_market, true, leverage);
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
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        
        let fa = primary_fungible_store::withdraw(
            user,
            vault_data.asset_metadata,
            amount
        );
        
        fungible_asset::deposit(vault_data.store, fa);
    }

    public entry fun withdraw(
        user: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_addr = object::object_address(&vault);
        let vault_data = borrow_global<Vault>(vault_addr);
        
        let balance = fungible_asset::balance(vault_data.store);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let fa = fungible_asset::withdraw(&vault_signer, vault_data.store, amount);
        
        primary_fungible_store::deposit(signer::address_of(user), fa);
    }

    public entry fun long_position(
        sender: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let fa = fungible_asset::withdraw(&vault_signer, vault_data.store, amount);
        perp_engine::deposit(&vault_signer, fa);

        let best_ask_opt = perp_market::best_ask_price(vault_data.perp_market);
        
        let execution_price = if (option::is_some<u64>(&best_ask_opt)) {
            let ask_price = option::destroy_some(best_ask_opt);
            ask_price + (ask_price * 5 / 1000)
        } else {
            let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
            mark_price + (mark_price * 5 / 1000)
        };
        
        let size_decimals = perp_engine::market_sz_decimals(vault_data.perp_market);
        
        let collateral_value = (amount as u128) * (vault_data.leverage as u128);
        let size_scale = math64::pow(10, (size_decimals as u64));
        let size_raw = (collateral_value * (size_scale as u128)) / (execution_price as u128);
        let size = (size_raw as u64);
        
        perp_engine::place_market_order(
            vault_data.perp_market,
            &vault_signer,
            size,
            true, // is_bid = true (long/buy)
            false, // is_reduce_only = false
            option::none<String>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<BuilderCode>(),
        );
    }

    public entry fun close_position(
        sender: &signer,
        vault: Object<Vault>,
    ) acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let position_size = perp_engine::get_position_size(signer::address_of(&vault_signer), vault_data.perp_market);
        let is_long = perp_engine::get_position_is_long(signer::address_of(&vault_signer), vault_data.perp_market);
        
        if (position_size > 0) {
            perp_engine::place_market_order(
                vault_data.perp_market,
                &vault_signer,
                position_size,
                !is_long, // is_bid = opposite of current position
                true, // is_reduce_only = true
                option::none<String>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<u64>(),
                option::none<BuilderCode>(),
            );
        }
    }

    public entry fun short_position(
        sender: &signer,
        vault: Object<Vault>,
        amount: u64,
    ) acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        
        let vault_signer = object::generate_signer_for_extending(&vault_data.extend_ref);
        
        let fa = fungible_asset::withdraw(&vault_signer, vault_data.store, amount);
        perp_engine::deposit(&vault_signer, fa);
        assert!(perp_engine::get_position_is_long(signer::address_of(&vault_signer), vault_data.perp_market) == true, 0);
        let best_bid_opt = perp_market::best_bid_price(vault_data.perp_market);
        
        let execution_price = if (option::is_some<u64>(&best_bid_opt)) {
            let bid_price = option::destroy_some(best_bid_opt);
            bid_price - (bid_price * 5 / 1000)
        } else {
            let mark_price = perp_engine::get_mark_price(vault_data.perp_market);
            mark_price - (mark_price * 5 / 1000)
        };
        let size_decimals = perp_engine::market_sz_decimals(vault_data.perp_market);
        let collateral_value = (amount as u128) * (vault_data.leverage as u128);
        let size_scale = math64::pow(10, (size_decimals as u64));
        let size_raw = (collateral_value * (size_scale as u128)) / (execution_price as u128);
        let size = (size_raw as u64);
        
        perp_engine::place_market_order(
            vault_data.perp_market,
            &vault_signer,
            size,
            false, // is_bid = false (short/sell)
            true, // is_reduce_only = true
            option::none<String>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<u64>(),
            option::none<BuilderCode>(),
        );
    }

    #[view]
    public fun get_balance(vault: Object<Vault>): u64 acquires Vault {
        let vault_data = borrow_global<Vault>(object::object_address(&vault));
        fungible_asset::balance(vault_data.store)
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
}