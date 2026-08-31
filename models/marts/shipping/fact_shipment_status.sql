select
    shipment_status_key
    , shipment_id
    , status
    , occurred_at
from {{ ref('inter_shipments_status') }}