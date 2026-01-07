module decibel_dex::chainlink_state {

    public fun convert_price(p0: vector<u8>, p1: u8, p2: i8, p3: u8): (u64, u32)
    {
        (0, 0)
    }
    public fun get_latest_price(p0: vector<u8>): (u256, u32)
    {
        (0,0)
    }
    public fun get_converted_price(p0: vector<u8>, p1: i8, p2: u8): u64
    {
        0
    }
    public fun is_price_negative(p0: u256): bool {
        p0 & 3138550867693340381917894711603833208051177722232017256448u256 != 0u256
    }
}
