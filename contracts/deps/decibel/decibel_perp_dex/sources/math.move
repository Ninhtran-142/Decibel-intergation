module decibel_dex::math {
    use 0x1::math64;
    // friend decibel_dex::chainlink_state;
    // friend decibel_dex::oracle;
    // friend decibel_dex::perp_market_config;
    friend decibel_dex::collateral_balance_sheet;
    // friend decibel_dex::position_update;
    friend decibel_dex::accounts_collateral;
    friend decibel_dex::perp_engine;
    struct Precision has copy, drop, store {
        decimals: u8,
        multiplier: u64,
    }

    public(friend) fun new_precision(p0: u8): Precision {
        let _v0 = p0 as u64;
        let _v1 = math64::pow(10, _v0);
        Precision{decimals: p0, multiplier: _v1}
    }
}
