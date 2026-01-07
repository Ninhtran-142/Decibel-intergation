module decibel_dex::dex_accounts {
    use aptos_std::ordered_map;
    use std::option;
    use aptos_framework::object;
    use decibel_dex::perp_market;
    use decibel_dex::perp_engine_api;
    use aptos_std::big_ordered_map;
    use aptos_framework::fungible_asset;
    use std::signer;
    enum StoredPermission has copy, drop, store {
        Unlimited,
        UnlimitedUntil {
            _0: u64
        }
    }

    enum DelegatedPermissions has copy, drop, store {
        V1 {
            perms: ordered_map::OrderedMap<PermissionType, StoredPermission>
        }
    }

    enum PermissionType has copy, drop, store {
        TradePerpsAllMarkets,
        TradePerpsOnMarket {
            market: object::Object<perp_market::PerpMarket>
        }
        SubaccountFundsMovement,
        SubDelegate,
        TradeVaultTokens
    }

    enum RestrictedApiRegistry has key {
        V1 {
            restricted_perp_api: perp_engine_api::RestrictedPerpApi
        }
    }

    enum Subaccount has key {
        V1 {
            extend_ref: object::ExtendRef,
            delegated_permissions: big_ordered_map::BigOrderedMap<address, DelegatedPermissions>,
            is_active: bool
        }
    }

    public fun register_restricted_api(p0: &signer) {
        abort 0;
    }

    public entry fun configure_user_settings_for_market(
        p0: &signer,
        p1: address,
        p2: object::Object<perp_market::PerpMarket>,
        p3: bool,
        p4: u8
    ) acquires RestrictedApiRegistry, Subaccount {
        abort 0;
    }

    public entry fun transfer_margin_to_isolated_position(
        p0: &signer,
        p1: object::Object<Subaccount>,
        p2: object::Object<perp_market::PerpMarket>,
        p3: bool,
        p4: object::Object<fungible_asset::Metadata>,
        p5: u64
    ) acquires Subaccount {
        abort 0;
    }

    public entry fun deposit_to_isolated_position_margin(
        p0: &signer,
        p1: object::Object<Subaccount>,
        p2: object::Object<perp_market::PerpMarket>,
        p3: object::Object<fungible_asset::Metadata>,
        p4: u64
    ) acquires Subaccount {
        abort 0;
    }

    public entry fun withdraw_from_isolated_position_margin(
        p0: &signer,
        p1: object::Object<Subaccount>,
        p2: object::Object<perp_market::PerpMarket>,
        p3: object::Object<fungible_asset::Metadata>,
        p4: u64
    ) acquires Subaccount {
        abort 0;
    }

    public entry fun deposit_to_subaccount_at(
        p0: &signer,
        p1: address,
        p2: object::Object<fungible_asset::Metadata>,
        p3: u64
    ) acquires RestrictedApiRegistry, Subaccount {
        abort 0;
    }

    public entry fun cancel_order_to_subaccount(
        p0: &signer,
        p1: object::Object<Subaccount>,
        p2: u128,
        p3: object::Object<perp_market::PerpMarket>
    ) acquires Subaccount {
        abort 0;
    }

    public entry fun create_new_seeded_subaccount(
        p0: &signer, p1: vector<u8>
    ) acquires RestrictedApiRegistry {
        abort 0;
    }

    public entry fun create_new_subaccount(p0: &signer) acquires RestrictedApiRegistry {
        abort 0;
    }

    public fun create_new_subaccount_object(
        p0: &signer
    ): object::Object<Subaccount> acquires RestrictedApiRegistry {
        object::address_to_object<Subaccount>(signer::address_of(p0))
    }

    public fun delegate_onchain_account_permissions(
        p0: &object::ExtendRef,
        p1: address,
        p2: address,
        p3: bool,
        p4: bool,
        p5: bool,
        p6: bool,
        p7: option::Option<u64>
    ) acquires RestrictedApiRegistry, Subaccount {
        abort 0;
    }

    public fun deposit_funds_to_subaccount_at(
        p0: &signer, p1: address, p2: fungible_asset::FungibleAsset
    ) acquires RestrictedApiRegistry, Subaccount {
        abort 0;
    }

    public fun primary_subaccount(p0: address): address {
        object::create_object_address(
            &p0,
            vector[
                100u8, 101u8, 99u8, 105u8, 98u8, 101u8, 108u8, 95u8, 100u8, 101u8, 120u8,
                95u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 95u8, 118u8, 50u8
            ]
        )
    }

    public entry fun init_account_status_cache_for_subaccount(
        p0: &signer, p1: address
    ) acquires Subaccount {
        abort 0;
    }

    public fun primary_subaccount_object(p0: address): object::Object<Subaccount> {
        object::address_to_object<Subaccount>(
            object::create_object_address(
                &p0,
                vector[
                    100u8, 101u8, 99u8, 105u8, 98u8, 101u8, 108u8, 95u8, 100u8, 101u8,
                    120u8, 95u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 95u8,
                    118u8, 50u8
                ]
            )
        )
    }

    public entry fun transfer_collateral_between_subaccounts(
        p0: &signer,
        p1: object::Object<Subaccount>,
        p2: object::Object<Subaccount>,
        p3: object::Object<fungible_asset::Metadata>,
        p4: u64
    ) acquires Subaccount {
        abort 0;
    }

    public fun withdraw_from_subaccount_request(
        p0: &signer,
        p1: object::Object<Subaccount>,
        p2: object::Object<fungible_asset::Metadata>,
        p3: u64
    ): bool acquires Subaccount {
        true
    }

    public fun withdraw_onchain_account_funds_from_subaccount(
        p0: &object::ExtendRef,
        p1: object::Object<Subaccount>,
        p2: object::Object<fungible_asset::Metadata>,
        p3: u64
    ): fungible_asset::FungibleAsset acquires Subaccount {
        fungible_asset::zero(p2)
    }
}
