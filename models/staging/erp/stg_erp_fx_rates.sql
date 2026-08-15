with erp_fex_rates_cleaned as (
    select
        trim(upper(from_currency))               as from_currency
        , trim(upper(to_currency))               as to_currency
        , trim(upper(rate_type))                 as rate_type
        , trim(upper(source_system))             as source_system
        , rate::decimal(18, 8)
        , rate_date::date
        , loaded_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as loaded_at
        , created_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as created_at
        , updated_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as updated_at
        , dw_run_timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as dw_run_timestamp
    from erp.fx_rates
)

select * from erp_fex_rates_cleaned