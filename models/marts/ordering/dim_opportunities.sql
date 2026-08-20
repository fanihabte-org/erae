select
    opportunity_key
    , opportunity_id
    , name
    , stage_name
    , loss_reason
    , lead_source
    , currency_iso_code
    , is_deleted
    , discount_percent
    , probability
    , amount
    , close_date
    , creation_date
    , valid_from
    , valid_to
    , is_current
from {{ ref('inter_opportunities') }}
