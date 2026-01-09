module decibel_dex::dex_accounts_vault_extension {
    use 0x1::fungible_asset;
    use 0x1::object;
    use decibel_dex::dex_accounts;
    use decibel_dex::perp_engine;
    use 0x1::signer;
    enum ExternalCallbacks has key {
        V1 {
            vault_contribute_funds_f: |&signer, address, fungible_asset::FungibleAsset| has copy + drop + store,
            vault_redeem_and_deposit_to_dex_f: |&signer, address, u64| has copy + drop + store,
        }
    }
    public entry fun contribute_to_vault(p0: &signer, p1: object::Object<dex_accounts::Subaccount>, p2: address, p3: object::Object<fungible_asset::Metadata>, p4: u64)
    {
        abort 0;
    }
    public entry fun redeem_from_vault(p0: &signer, p1: object::Object<dex_accounts::Subaccount>, p2: address, p3: u64)
    {
        abort 0;
    }
   
}
