module decibel_dex::vault_share_asset {
    use 0x1::fungible_asset;
    use 0x1::object;
    
    public fun can_withdraw(
        p0: object::Object<fungible_asset::Metadata>, p1: address, p2: u64
    ): bool {
        true
    }

    public fun cleanup_expired_entries(p0: address, p1: address) {
        abort 0;
    }

    public fun get_user_unlocked_balance(
        p0: object::Object<fungible_asset::Metadata>, p1: address
    ): u64 {
        0
    }

    public fun vault_share_withdraw<T0: key>(
        p0: object::Object<T0>, p1: u64, p2: &fungible_asset::TransferRef
    ): fungible_asset::FungibleAsset {
        fungible_asset::zero(p0)
    }
}
