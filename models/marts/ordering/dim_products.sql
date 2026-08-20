select
    product_key
    , product_id
    , name
    , category
    , family
    , price_usd
    , cost_usd
    , is_active
    , discontinued_on
    , launch_date
    , valid_from
    , valid_to
    , is_current
from {{ ref('inter_products') }}