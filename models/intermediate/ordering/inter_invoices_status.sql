with invoices_all_states as (
    select
        id             as invoice_status_key
        , invoice_id
        , new_status   as status
        , occurred_at
    from {{ ref('stg_invoice_status_history') }}
)

select * from invoices_all_states