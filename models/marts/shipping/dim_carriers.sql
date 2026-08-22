select
    carrier_key
    , carrier_id
    , name
    , mode
    , cost_index
    , otd_rate
    , valid_from
    , valid_to
    , is_current
from {{ ref('inter_carriers') }}