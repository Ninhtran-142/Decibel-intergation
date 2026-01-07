module decibel_dex::perp_engine_types {
    use aptos_experimental::order_book_types;
    use 0x1::option;
    use decibel_dex::builder_code_registry;

    enum ChildTpSlOrder has copy, drop, store {
        V1 {
            trigger_price: u64,
            parent_order_id: order_book_types::OrderIdType,
            limit_price: option::Option<u64>
        }
    }

    struct OrderActions has copy, drop, store {
        actions: vector<SingleOrderAction>
    }

    enum SingleOrderAction has copy, drop, store {
        CancelOrder {
            account: address,
            order_id: order_book_types::OrderIdType
        }
        ReduceOrderSize {
            account: address,
            order_id: order_book_types::OrderIdType,
            size_delta: u64
        }
    }

    enum OrderMatchingActions has copy, drop, store {
        SettleTradeMatchingActions {
            _0: OrderActions
        }
        PlaceMakerOrderActions {
            _0: OrderActions
        }
    }

    enum OrderMetadata has copy, drop, store {
        V1_RETAIL {
            is_reduce_only: bool,
            use_backstop_liquidation_margin: bool,
            is_margin_call: bool,
            twap: option::Option<TwapMetadata>,
            tp_sl: TpSlMetadata,
            builder_code: option::Option<builder_code_registry::BuilderCode>
        }
        V1_BULK {
            builder_code: option::Option<builder_code_registry::BuilderCode>
        }
    }

    enum TwapMetadata has copy, drop, store {
        V1 {
            start_time_seconds: u64,
            frequency_seconds: u64,
            end_time_seconds: u64
        }
    }

    enum TpSlMetadata has copy, drop, store {
        V1 {
            tp: option::Option<ChildTpSlOrder>,
            sl: option::Option<ChildTpSlOrder>
        }
    }
}
