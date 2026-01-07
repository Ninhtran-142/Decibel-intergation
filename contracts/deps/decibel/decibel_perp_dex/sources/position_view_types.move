module decibel_dex::position_view_types {
    use 0x1::object;
    use decibel_dex::perp_market;
    enum PositionViewInfo has drop {
        V1 {
            market: object::Object<perp_market::PerpMarket>,
            size: u64,
            is_long: bool,
            user_leverage: u8,
            is_isolated: bool,
        }
    }
    public fun get_position_info_is_isolated(p0: &PositionViewInfo): bool {
        *&p0.is_isolated
    }
    public fun get_position_info_is_long(p0: &PositionViewInfo): bool {
        *&p0.is_long
    }
    public fun get_position_info_market(p0: &PositionViewInfo): object::Object<perp_market::PerpMarket> {
        *&p0.market
    }
    public fun get_position_info_size(p0: &PositionViewInfo): u64 {
        *&p0.size
    }
    public fun get_position_info_user_leverage(p0: &PositionViewInfo): u8 {
        *&p0.user_leverage
    }
}
