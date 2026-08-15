with ops_carriers_cleaned as (
    select
        trim(upper(carrier_code))                as id
        , trim(upper(carrier_name))              as name
        , trim(upper(mode))                      as mode
        , cost_index::decimal(4,3)
        , published_otd_rate::decimal(4,3)
        , created_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as created_at
        , updated_at::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'carriers') }}
)

select * from ops_carriers_cleaned