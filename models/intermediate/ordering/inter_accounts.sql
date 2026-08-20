with snapshot_accounts as (
    select * from {{ ref('accounts_snapshot') }}
)

select
    dbt_scd_id                    as account_key
    , id                          as account_id
    , owner_id
    , name
    , account_number
    , industry
    , type
    , billing_country
    , is_deleted
    , annual_revenue
    , number_of_employees
    , dbt_valid_from                    as valid_from
    , coalesce(dbt_valid_to,
               '9999-12-31'::timestamp) as valid_to
    , dbt_valid_to is null              as is_current
from snapshot_accounts