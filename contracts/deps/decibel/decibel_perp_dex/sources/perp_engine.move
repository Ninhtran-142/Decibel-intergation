module decibel_dex::perp_engine {
    use aptos_framework::object;
    use aptos_std::big_ordered_map;
    use decibel_dex::perp_market;
    use aptos_framework::fungible_asset;
    use std::string;
    use std::option;
    use decibel_dex::builder_code_registry;
    use decibel_dex::position_view_types;
    use aptos_experimental::order_book_types;

    enum Global has key {
        V1 {
            extend_ref: object::ExtendRef,
            market_refs: big_ordered_map::BigOrderedMap<object::Object<perp_market::PerpMarket>, object::ExtendRef>,
            is_exchange_open: bool
        }
    }

    public fun collateral_balance_decimals(): u8 {
        0
    }

    public fun deposit(p0: &signer, p1: fungible_asset::FungibleAsset)
    {
        abort 0;
    }

    public fun cancel_bulk_order(
        p0: object::Object<perp_market::PerpMarket>, p1: &signer
    )
    {
        abort 0;
    }

    public fun place_bulk_order(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: u64,
        p3: vector<u64>,
        p4: vector<u64>,
        p5: vector<u64>,
        p6: vector<u64>,
        p7: option::Option<builder_code_registry::BuilderCode>
    ): order_book_types::OrderIdType
    {
        order_book_types::next_order_id()
    }

    public fun cancel_order(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: order_book_types::OrderIdType
    )
    {
        abort 0;
    }

    public fun place_market_order(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: u64,
        p3: bool,
        p4: bool,
        p5: option::Option<string::String>,
        p6: option::Option<u64>,
        p7: option::Option<u64>,
        p8: option::Option<u64>,
        p9: option::Option<u64>,
        p10: option::Option<u64>,
        p11: option::Option<builder_code_registry::BuilderCode>
    ): order_book_types::OrderIdType
    {
        order_book_types::next_order_id()
    }

    public fun place_order(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: u64,
        p3: u64,
        p4: bool,
        p5: order_book_types::TimeInForce,
        p6: bool,
        p7: option::Option<string::String>,
        p8: option::Option<u64>,
        p9: option::Option<u64>,
        p10: option::Option<u64>,
        p11: option::Option<u64>,
        p12: option::Option<u64>,
        p13: option::Option<builder_code_registry::BuilderCode>
    ): order_book_types::OrderIdType
    {
        order_book_types::next_order_id()
    }

    public fun cancel_client_order(
        p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: string::String
    )
    {
        abort 0;
    }

    public fun get_oracle_price(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun get_primary_store_balance_in_balance_precision(): u64 {
        0
    }

    public fun primary_asset_metadata(): object::Object<fungible_asset::Metadata> {
        object::address_to_object<fungible_asset::Metadata>(@0x1)
    }

    public fun get_mark_and_oracle_price(
        p0: object::Object<perp_market::PerpMarket>
    ): (u64, u64) {
        (0, 0)
    }

    public fun get_mark_price(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun market_max_leverage(
        p0: object::Object<perp_market::PerpMarket>
    ): u8 {
        0
    }

    public fun configure_user_settings_for_market(
        p0: &signer,
        p1: object::Object<perp_market::PerpMarket>,
        p2: bool,
        p3: u8
    )
    {
        abort 0;
    }

    public fun get_position_is_long(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): bool {
        true
    }

    public fun get_position_size(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun has_any_assets_or_positions(p0: address): bool {
        true
    }

    public fun has_position(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): bool {
        true
    }

    public fun is_position_isolated(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): bool {
        true
    }

    public fun is_position_liquidatable(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): bool {
        true
    }

    public fun transfer_margin_to_isolated_position(
        p0: &signer,
        p1: object::Object<perp_market::PerpMarket>,
        p2: bool,
        p3: object::Object<fungible_asset::Metadata>,
        p4: u64
    )
    {
        abort 0;
    }

    public fun deposit_to_isolated_position_margin(
        p0: &signer,
        p1: object::Object<perp_market::PerpMarket>,
        p2: fungible_asset::FungibleAsset
    )
    {
        abort 0;
    }

    public fun get_account_balance_fungible(p0: address): u64 {
        0
    }

    public fun get_account_net_asset_value_fungible(
        p0: address, p1: bool
    ): i64 {
        0
    }

    public fun get_isolated_position_margin(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun max_allowed_withdraw_fungible_amount(
        p0: address, p1: object::Object<fungible_asset::Metadata>
    ): u64 {
        0
    }

    public fun withdraw_fungible(
        p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64
    ): fungible_asset::FungibleAsset
    {
        fungible_asset::zero(p1)
    }

    public fun get_current_open_interest(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun get_max_notional_open_interest(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun cancel_twap_order(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: order_book_types::OrderIdType
    )
    {
        abort 0;
    }

    public fun market_min_size(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun cancel_orders(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: vector<order_book_types::OrderIdType>
    )
    {
        abort 0;
    }

    public fun cancel_tp_sl_order_for_position(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: order_book_types::OrderIdType
    )
    {
        abort 0;
    }

    public fun get_blp_pnl(p0: object::Object<perp_market::PerpMarket>): i64 {
        0
    }

    public fun get_max_open_interest_delta(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun get_position_avg_price(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun get_position_entry_price_times_size_sum(
        p0: address, p1: object::Object<perp_market::PerpMarket>
    ): u128 {
        0
    }

    public fun get_remaining_size_for_order(
        p0: object::Object<perp_market::PerpMarket>, p1: u128
    ): u64 {
        0
    }

    public fun is_market_open(
        p0: object::Object<perp_market::PerpMarket>
    ): bool {
        true
    }

    public fun is_supported_collateral(
        p0: object::Object<fungible_asset::Metadata>
    ): bool {
        true
    }

    public fun list_markets(): vector<address> {
        vector[]
    }

    public fun market_lot_size(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun market_margin_call_fee_pct(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun market_slippage_pcts(
        p0: object::Object<perp_market::PerpMarket>
    ): vector<u64> {
        vector[]
    }

    public fun market_sz_decimals(
        p0: object::Object<perp_market::PerpMarket>
    ): u8 {
        0
    }

    public fun market_ticker_size(
        p0: object::Object<perp_market::PerpMarket>
    ): u64 {
        0
    }

    public fun place_tp_sl_order_for_position(
        p0: object::Object<perp_market::PerpMarket>,
        p1: &signer,
        p2: option::Option<u64>,
        p3: option::Option<u64>,
        p4: option::Option<u64>,
        p5: option::Option<u64>,
        p6: option::Option<u64>,
        p7: option::Option<u64>,
        p8: option::Option<builder_code_registry::BuilderCode>
    ): (
        option::Option<order_book_types::OrderIdType>,
        option::Option<order_book_types::OrderIdType>
    )
    {
        (
            option::none<order_book_types::OrderIdType>(),
            option::none<order_book_types::OrderIdType>()
        )
    }

    public fun update_order(
        p0: &signer,
        p1: order_book_types::OrderIdType,
        p2: object::Object<perp_market::PerpMarket>,
        p3: u64,
        p4: u64,
        p5: bool,
        p6: order_book_types::TimeInForce,
        p7: bool,
        p8: option::Option<u64>,
        p9: option::Option<u64>,
        p10: option::Option<u64>,
        p11: option::Option<u64>,
        p12: option::Option<builder_code_registry::BuilderCode>
    )
    {
        abort 0;
    }

    public fun withdraw_from_isolated_position_margin(
        p0: &signer,
        p1: object::Object<perp_market::PerpMarket>,
        p2: object::Object<fungible_asset::Metadata>,
        p3: u64
    ): fungible_asset::FungibleAsset
    {
        fungible_asset::zero(p1)
    }

    public fun view_position(p0: address, p1: object::Object<perp_market::PerpMarket>): option::Option<position_view_types::PositionViewInfo> {
        option::none<position_view_types::PositionViewInfo>()
    }

    public fun list_positions(p0: address): vector<position_view_types::PositionViewInfo> {
        vector[]
    }
}
