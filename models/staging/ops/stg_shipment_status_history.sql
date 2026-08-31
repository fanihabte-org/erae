with ops_shipment_status_history_cleaned as (
    select
        shipment_status_event_id  as id
        , shipment_id
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
    from {{ source('operations', 'shipment_status_history') }}
)

select * from ops_shipment_status_history_cleaned