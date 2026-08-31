with order_status_all as (
    select
        id             as shipment_status_key
        , shipment_id
        , new_status   as status
        , occurred_at
    from {{ ref('stg_shipment_status_history') }}
)

select * from order_status_all
