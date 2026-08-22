select
    shipment_key
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
from {{ ref('inter_shipments') }}