module decibel_dex::vault {
    use 0x1::object;
    use 0x1::fungible_asset;
    use decibel_dex::perp_market;
    use aptos_experimental::order_book_types;
    use 0x1::option;

    friend decibel_dex::vault_api;

    enum Vault has key {
        V1 {
            admin: address,
            vault_ref: object::ExtendRef,
            contribution_asset_type: object::Object<fungible_asset::Metadata>,
            share_def: VaultShareDef,
            contribution_config: VaultContributionConfig,
            fee_config: VaultFeeConfig,
            fee_state: VaultFeeState,
            portfolio: VaultPortfolio,
        }
    }
    enum VaultShareDef has store {
        V1 {
            share_asset_type: object::Object<fungible_asset::Metadata>,
        }
    }
    enum VaultContributionConfig has store {
        V1 {
            max_outstanding_shares_when_contributing: u64,
            accepts_contributions: bool,
            contribution_lockup_duration_s: u64,
        }
    }
    enum VaultFeeConfig has store {
        V1 {
            fee_bps: u64,
            fee_recipient: address,
            fee_interval_s: u64,
        }
    }
    enum VaultFeeState has store {
        V1 {
            last_fee_distribution_time_s: u64,
            last_fee_distribution_nav: u64,
            last_fee_distribution_shares: u64,
        }
    }
    enum VaultPortfolio has drop, store {
        V1 {
            dex_primary_subaccount: address,
        }
    }
    struct OrderRef has copy, drop, store {
        market: object::Object<perp_market::PerpMarket>,
        order_id: order_book_types::OrderIdType,
    }


    public entry fun distribute_fees(p0: object::Object<Vault>)
    {
        abort 0;
    }

    public entry fun activate_vault(p0: &signer, p1: object::Object<Vault>, p2: u64)
    {
        abort 0;
    }
    
    public entry fun change_admin(p0: &signer, p1: object::Object<Vault>, p2: address)
    {
        abort 0;
    }
   
    public entry fun delegate_dex_actions_to(p0: &signer, p1: object::Object<Vault>, p2: address, p3: option::Option<u64>)
    {
        abort 0;
    }
    public fun get_order_ref_market(p0: &OrderRef): object::Object<perp_market::PerpMarket> {
        *&p0.market
    }
    public fun get_order_ref_order_id(p0: &OrderRef): order_book_types::OrderIdType {
        *&p0.order_id
    }
    public fun get_vault_admin(p0: object::Object<Vault>): address
        acquires Vault
    {
        let _v0 = object::object_address<Vault>(&p0);
        *&borrow_global<Vault>(_v0).admin
    }
    public fun get_vault_contribution_asset_type(p0: object::Object<Vault>): object::Object<fungible_asset::Metadata>
        acquires Vault
    {
        let _v0 = object::object_address<Vault>(&p0);
        *&borrow_global<Vault>(_v0).contribution_asset_type
    }
    public fun get_vault_net_asset_value(p0: object::Object<Vault>): u64
    {
        0
    }
    public fun get_vault_num_shares(p0: object::Object<Vault>): u64
    {
        0
    }

    public fun get_vault_portfolio_subaccounts(p0: object::Object<Vault>): vector<address>
        acquires Vault
    {
        let _v0 = object::object_address<Vault>(&p0);
        let _v1 = *&(&borrow_global<Vault>(_v0).portfolio).dex_primary_subaccount;
        let _v2 = 0x1::vector::empty<address>();
        0x1::vector::push_back<address>(&mut _v2, _v1);
        _v2
    }
    public fun get_vault_share_asset_type(p0: object::Object<Vault>): object::Object<fungible_asset::Metadata>
        acquires Vault
    {
        let _v0 = object::object_address<Vault>(&p0);
        *&(&borrow_global<Vault>(_v0).share_def).share_asset_type
    }
    
    public entry fun update_vault_contribution_lockup_duration(p0: &signer, p1: object::Object<Vault>, p2: u64)
    {
        abort 0;
    }

    public entry fun update_vault_fee_recipient(p0: &signer, p1: object::Object<Vault>, p2: address)
    {
        abort 0;
    }
    public entry fun update_vault_max_outstanding_shares(p0: &signer, p1: object::Object<Vault>, p2: u64)
    {
        abort 0;
    }
}
