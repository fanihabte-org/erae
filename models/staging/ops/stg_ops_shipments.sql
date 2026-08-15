with ops_shipments_cleaned as (
    select
        shipment_id::bigint                    as id
        , order_id::bigint
        , trim(upper(warehouse_code))          as warehouse_id
        , trim(upper(carrier_code))            as carrier_id
        , trim(upper(service_level))           as service_level
        , package_count::int
        , gross_weight_kg::decimal(18,2)
        , distance_km::decimal(18,2)
        , freight_cost_usd::decimal(18,2)
        , trim(upper(tracking_number))         as tracking_number
        , ship_date::date
        , promised_delivery_date::date
        , delivered_date::date
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'shipments') }}
    order by 1, 2, 3
)

select * from ops_shipments_cleaned