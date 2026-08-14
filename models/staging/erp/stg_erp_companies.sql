with erp_companies_clean as (
    select
        company_code
        , company_name::varchar(100)
        , functional_currency::varchar(50) as currency_iso_code
        , country::varchar(60)
        , created_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as created_at
        , updated_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as updated_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as dw_run_timestamp
    from {{ source('finance', 'companies') }}
)

select * from erp_companies_clean
