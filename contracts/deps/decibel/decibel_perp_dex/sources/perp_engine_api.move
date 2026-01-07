module decibel_dex::perp_engine_api {
    use 0x1::string;
    use decibel_dex::builder_code_registry;

    enum RestrictedPerpApi has drop, store {
        V1 {
            init_user_if_new_f: |&signer, address| has copy + drop + store
        }
    }

    public fun register_referral_code(p0: &signer, p1: string::String) {
        abort 0;
    }

    public fun register_referrer(p0: &signer, p1: string::String) {
        abort 0;
    }

    public fun approve_max_fee(p0: &signer, p1: address, p2: u64) {
        abort 0;
    }

    public fun new_builder_code(p0: address, p1: u64): builder_code_registry::BuilderCode {
        builder_code_registry::new_builder_code(p0, p1)
    }

    public fun revoke_max_fee(p0: &signer, p1: address) {
        abort 0;
    }

    public fun init_user_if_new(
        p0: &RestrictedPerpApi, p1: &signer, p2: address
    ) {
        abort 0;
    }

    public fun get_restricted_perp_api(p0: &signer): RestrictedPerpApi {
        RestrictedPerpApi::V1 {
            init_user_if_new_f: |arg0, arg1| revoke_max_fee(arg0, arg1)
        }
    }
}
