with snapshot_opportunity as (
    select * from {{ ref('opportunities_snapshot') }}
)

select
    opps.dbt_scd_id                     as opportunity_key
    , opps.id                           as opportunity_id
    , opps.name
    , opps.stage_name
    , opps.loss_reason
    , opps.lead_source
    , opps.currency_iso_code
    , opps.is_deleted
    , opps.discount_percent
    , opps.probability
    , opps.amount
    , opps.close_date
    , opps.created_at                   as creation_date
    , opps.dbt_valid_from               as valid_from
    , coalesce(opps.dbt_valid_to,
               '9999-12-31'::timestamp) as valid_to
    , dbt_valid_to is null              as is_current
from snapshot_opportunity opps
