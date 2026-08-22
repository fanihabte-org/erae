with shipments_dimension_joined as (
    select
        sos.shipment_id
        , io.order_key
        , iw.warehouse_key
        , ic.carrier_key
        , sos.shipment_type
        , sos.package_count
        , sos.gross_weight_kg
        , sos.distance_km
        , sos.freight_cost_usd
        , sos.ship_date
        , sos.promise_date
        , sos.delivery_date
    from {{ ref('stg_ops_shipments') }} sos
    left join {{ ref('inter_warehouses')}} iw
        on sos.warehouse_id = iw.warehouse_id
        and sos.created_at >= iw.valid_from
        and sos.created_at < iw.valid_to
    left join {{ ref('inter_carriers')}} ic
        on sos.carrier_id = ic.carrier_id
        and sos.created_at >= ic.valid_from
        and sos.created_at < ic.valid_to
    left join {{ ref('inter_orders')}} io
        on sos.order_id = io.order_id
)

, shipment_with_date_keys as (
    select
        sdj.shipment_id
        , sdj.order_key
        , sdj.warehouse_key
        , sdj.carrier_key
        , sdj.shipment_type
        , sdj.package_count
        , sdj.gross_weight_kg
        , sdj.distance_km
        , sdj.freight_cost_usd
        , sdd.date_key         as ship_date_key
        , pdd.date_key         as promise_date_key
        , ddd.date_key         as delivery_date_key
    from shipments_dimension_joined sdj
    left join {{ ref('inter_dates') }} sdd
        on sdj.ship_date = sdd.full_date
    left join {{ ref('inter_dates') }} pdd
        on sdj.promise_date = pdd.full_date
    left join {{ ref('inter_dates') }} ddd
        on sdj.delivery_date = ddd.full_date
)

, final_shipments_with_key as (
    select
        {{
            dbt_utils.generate_surrogate_key(
                ['shipment_id', 'ship_date_key'
                ,'promise_date_key' ,'delivery_date_key']
            )
        }}                         as shipment_key
        , shipment_id
        , order_key
        , warehouse_key
        , carrier_key
        , shipment_type
        , package_count
        , gross_weight_kg
        , distance_km
        , freight_cost_usd
        , ship_date_key
        , promise_date_key
        , delivery_date_key
    from  shipment_with_date_keys
)

select * from final_shipments_with_key