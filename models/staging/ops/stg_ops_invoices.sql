with ops_invoices_cleaned as (
    select
        invoice_id::bigint            as id
        , trim(upper(invoice_number)) as invoice_number
        , order_id::bigint            as order_id
        , trim(upper(currency_code))  as currency_iso_code
        , trim(upper(status))         as status
        , amount::decimal(18,2)
        , invoice_date::date
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'invoices') }}
    order by 1, 2, 3
)

select * from ops_invoices_cleaned