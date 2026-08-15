with ops_support_case_cleaned as (
    select
        case_id::bigint                        as id
        , customer_id::bigint                  as customer_id
        , trim(upper(case_type))               as case_type
        , trim(upper(priority))                as priority
        , trim(upper(channel))                 as channel
        , trim(upper(status))                  as status
        , trim(upper(assigned_region))         as region
        , resolution_hours::decimal(18,2)
        , csat_score::int
        , opened_at::timestamp
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'support_cases') }}
    order by 1, 2, 3
)

select * from ops_support_case_cleaned