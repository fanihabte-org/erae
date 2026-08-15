with erp_gl_accounts_cleaned as (
    select
        gl_account::int                          as id
        , trim(upper(gl_name))                   as name
        , trim(upper(account_type))              as account_type
        , is_postable::boolean
        , created_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as created_at
        , updated_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as updated_at
        , dw_run_timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('finance','gl_accounts') }}
)

select * from erp_gl_accounts_cleaned