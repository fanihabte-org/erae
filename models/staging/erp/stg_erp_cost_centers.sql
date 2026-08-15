with erp_cost_centers_cleaned as (
    select
        trim(upper(cost_center_code))       as id
        , trim(upper(cost_center_name))     as name
        , trim(upper(company_code))         as company_id
        , trim(upper(region))               as region
        , trim(upper(function))             as function
        , trim(upper(owner_email))          as email
        , is_active::boolean
        , valid_from::date
        , valid_to::date
        , created_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'     as created_at
        , updated_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'     as updated_at
        , dw_run_timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'     as dw_run_timestamp
    from {{ source('finance', 'cost_centers') }}
)

select * from erp_cost_centers_cleaned