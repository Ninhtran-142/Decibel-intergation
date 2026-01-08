module decibel_dex::vault_api {
    use 0x1::fungible_asset;
    use 0x1::option;
    use 0x1::object;
    use decibel_dex::dex_accounts;
    use 0x1::string;

    public entry fun process_pending_requests(p0: u32) {
        abort 0;
    }

    public entry fun create_and_fund_vault(
        p0: &signer,
        p1: option::Option<object::Object<dex_accounts::Subaccount>>,
        p2: object::Object<fungible_asset::Metadata>,
        p3: string::String,
        p4: string::String,
        p5: vector<string::String>,
        p6: string::String,
        p7: string::String,
        p8: string::String,
        p9: u64,
        p10: u64,
        p11: u64,
        p12: u64,
        p13: bool,
        p14: bool
    ) {
        abort 0;
    }
}
