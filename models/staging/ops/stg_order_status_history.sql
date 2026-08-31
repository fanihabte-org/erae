with ops_order_staus_history_cleaned as (
    select
        order_status_event_id::bigint  as id
        , order_id
        , source_event_id
        , previous_status
        , new_status
        , sla_due_at
        , sla_status
        , anomaly_type
        , occurred_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as occurred_at
        , recorded_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as recorded_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'order_status_history') }}
)

select * from ops_order_staus_history_cleaned