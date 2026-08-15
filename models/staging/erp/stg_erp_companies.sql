with erp_companies_clean as (
    select
        trim(upper(company_code))                as id
        , trim(upper(company_name))              as name
        , trim(upper(functional_currency))       as currency_iso_code
        , trim(upper(country))                   as country
        , created_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as created_at
        , updated_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('finance', 'companies') }}
)

select * from erp_companies_clean
