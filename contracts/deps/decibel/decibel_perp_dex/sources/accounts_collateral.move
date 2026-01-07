module decibel_dex::accounts_collateral {
    use 0x1::object;
    use 0x1::fungible_asset;
    use decibel_dex::math;
    use decibel_dex::perp_market;
    // friend decibel_dex::clearinghouse_perp;
    // friend decibel_dex::liquidation;
    // friend decibel_dex::async_matching_engine;
    friend decibel_dex::perp_engine;
    public fun is_asset_supported(p0: object::Object<fungible_asset::Metadata>): bool
    {
        true
    }
    public fun primary_asset_metadata(): object::Object<fungible_asset::Metadata>
    {
        object::address_to_object<fungible_asset::Metadata>(@0x1)
    }
    
    public fun get_account_balance(p0: address): u64
    {
        0
    }
    
    public fun available_order_margin(p0: address): u64
    {
        0
    }
    public fun collateral_balance_precision(): math::Precision
    {
        math::new_precision(0)
    }
    
    public fun get_account_balance_fungible(p0: address): u64
    {
        0
    }
    
    public fun get_account_secondary_asset_balance(p0: address, p1: object::Object<fungible_asset::Metadata>): u64
    {
        0
    }
    public fun get_account_usdc_balance(p0: address): i64
    {
        0
    }

    public fun get_isolated_position_margin(p0: address, p1: object::Object<perp_market::PerpMarket>): u64
    {
        0
    }
    public fun get_isolated_position_usdc_balance(p0: address, p1: object::Object<perp_market::PerpMarket>): i64
    {
        0
    }
    
}
