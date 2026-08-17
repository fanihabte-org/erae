with ops_orders_cleaned as (
    select
        order_id::bigint                  as id
        , customer_id::bigint
        , trim(opportunity_ref)::bigint   as opportunity_id
        , trim(upper(rep_id))             as rep_id
        , trim(upper(po_number))          as purchase_id
        , trim(upper(currency_code))      as currency_iso_code
        , trim(upper(status))             as status
        , trim(upper(sales_channel))      as sales_channel
        , order_discount_pct
        , order_date::date
        , requested_delivery_date::date
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'orders') }}
    order by 1, 2, 3
)

select * from ops_orders_cleaned
