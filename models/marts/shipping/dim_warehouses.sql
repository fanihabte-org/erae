select
    warehouse_key
    , warehouse_id
    , name
    , region
    , latitude
    , longitude
    , valid_from
    , valid_to
    , is_current
from {{ ref('inter_warehouses') }}