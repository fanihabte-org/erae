with ops_warehouse_cleaned as (
    select
        trim(upper(warehouse_code))            as id
        , trim(upper(warehouse_name))          as name
        , trim(upper(region))                  as region
        , latitude::decimal(18,5)
        , longitude::decimal(18,5)
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'warehouses')}}
    order by 1, 2, 3
)

select * from ops_warehouse_cleaned
