module decibel_dex::perp_market {
    use aptos_experimental::market_types;
    use decibel_dex::perp_engine_types;
    use 0x1::object;
    use aptos_experimental::order_book_types;
    use 0x1::option;

    enum PerpMarket has key {
        V1 {
            market: market_types::Market<perp_engine_types::OrderMetadata>
        }
    }

    public fun get_remaining_size(
        p0: object::Object<PerpMarket>, p1: order_book_types::OrderIdType
    ): u64
    {
        0
    }

    public fun best_ask_price(p0: object::Object<PerpMarket>): option::Option<u64> {
        option::none<u64>()
    }

    public fun best_bid_price(p0: object::Object<PerpMarket>): option::Option<u64> {
        option::none<u64>()
    }

    public fun get_best_bid_and_ask_price(
        p0: object::Object<PerpMarket>
    ): (option::Option<u64>, option::Option<u64>)
    {
        (option::none<u64>(), option::none<u64>())
    }
}
