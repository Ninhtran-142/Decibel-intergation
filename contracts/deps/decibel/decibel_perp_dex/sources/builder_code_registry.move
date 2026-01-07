module decibel_dex::builder_code_registry {
    use 0x1::big_ordered_map;
    friend decibel_dex::perp_engine;
    friend decibel_dex::perp_engine_api;
    struct BuilderAndAccount has copy, drop, store {
        account: address,
        builder: address
    }

    struct BuilderCode has copy, drop, store {
        builder: address,
        fees: u64
    }

    enum Registry has store, key {
        V1 {
            global_max_fee: u64,
            approved_max_fees: big_ordered_map::BigOrderedMap<BuilderAndAccount, u64>
        }
    }

    public fun get_approved_max_fee(p0: address, p1: address): u64 {
        0
    }

    public(friend) fun new_builder_code(p0: address, p1: u64): BuilderCode {
        BuilderCode { builder: p0, fees: p1 }
    }
}
