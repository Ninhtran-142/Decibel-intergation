module decibel_dex::i64_aggregator {
    use 0x1::aggregator_v2;
    friend decibel_dex::collateral_balance_sheet;
    //friend decibel_dex::perp_positions;
    enum I64Aggregator has drop, store {
        V1 {
            offset_balance: aggregator_v2::Aggregator<u64>,
        }
    }
    enum I64Snapshot has drop, store {
        V1 {
            offset_balance: aggregator_v2::AggregatorSnapshot<u64>,
        }
    }

    public(friend) fun create_i64_snapshot(p0: i64): I64Snapshot {
        I64Snapshot::V1{offset_balance: aggregator_v2::create_snapshot<u64>(((p0 as i128) + 9223372036854775808i128) as u64)}
    }

    public(friend) fun new_i64_aggregator(): I64Aggregator {
        I64Aggregator::V1{offset_balance: aggregator_v2::create_unbounded_aggregator_with_value<u64>(9223372036854775808)}
    }
}
