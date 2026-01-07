module decibel_dex::collateral_balance_sheet {
    use 0x1::object;
    use 0x1::fungible_asset;
    use decibel_dex::i64_aggregator;
    use 0x1::table;
    use decibel_dex::math;
    use decibel_dex::perp_market;
    use 0x1::primary_fungible_store;
    // friend decibel_dex::fee_distribution;
    // friend decibel_dex::perp_positions;
    // friend decibel_dex::position_update;
    friend decibel_dex::accounts_collateral;
    struct AssetBalance has copy, drop, store {
        asset_type: object::Object<fungible_asset::Metadata>,
        balance: u64,
    }
    enum CollateralBalanceChangeEvent has drop, store {
        V1 {
            asset_type: object::Object<fungible_asset::Metadata>,
            balance_type: CollateralBalanceType,
            delta: i64,
            offset_balance_after: i64_aggregator::I64Snapshot,
            change_type: CollateralBalanceChangeType,
        }
    }
    enum CollateralBalanceType has copy, drop, store {
        Cross {
            account: address,
        }
        Isolated {
            account: address,
            market: object::Object<perp_market::PerpMarket>,
        }
    }
    enum CollateralBalanceChangeType has copy, drop, store {
        UserMovement,
        Fee,
        PnL,
        Margin,
        Liquidation,
        TestOnly,
    }

    struct CollateralStore has store {
        asset_type: object::Object<fungible_asset::Metadata>,
        asset_precision: math::Precision,
        store: object::Object<fungible_asset::FungibleStore>,
        store_extend_ref: object::ExtendRef,
    }
    struct SecondaryBalances has drop, store {
        asset_balances: vector<AssetBalance>,
    }

    fun create_collateral_store(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: vector<u8>): CollateralStore {
        let _v0 = object::create_named_object(p0, p2);
        let _v1 = object::generate_extend_ref(&_v0);
        let _v2 = primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(object::address_from_constructor_ref(&_v0), p1);
        let _v3 = math::new_precision(fungible_asset::decimals<fungible_asset::Metadata>(p1));
        CollateralStore{asset_type: p1, asset_precision: _v3, store: _v2, store_extend_ref: _v1}
    }

    public(friend) fun balance_type_cross(p0: address): CollateralBalanceType {
        CollateralBalanceType::Cross{account: p0}
    }

    public(friend) fun change_type_fee(): CollateralBalanceChangeType {
        CollateralBalanceChangeType::Fee{}
    }

}
