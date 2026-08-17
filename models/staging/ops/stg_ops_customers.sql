with ops_customers_cleaned as (
    select
        customer_id::bigint           as id
        , trim(upper(account_number)) as account_number
        , trim(upper(company_code))   as company_id
        , trim(upper(customer_name))  as name
        , trim(upper(segment))        as segment
        , trim(upper(industry))       as industry
        , trim(upper(region))         as region
        , trim(upper(country))        as country
        , employee_count::int
        , credit_limit_usd::decimal(36,2)
        , payment_terms_days::int
        , is_active::boolean
        , created_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as created_at
        , updated_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'customers') }}
    order by 1, 2, 3
)

select * from ops_customers_cleaned
