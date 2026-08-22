with invoices_all_states as (
    select
        soi.invoice_id
        , soi.invoice_number
        , io.order_key
        , soi.currency_iso_code
        , soi.status
        , soi.amount
        , soi.invoice_date
        , soi.updated_at::date
    from {{ ref('stg_ops_invoices') }} soi
    left join {{ ref('inter_orders') }} io
        on soi.order_id = io.order_id
)

, invoice_event_dates_pivot as (
    select
        invoice_id
        , invoice_number
        , order_key
        , currency_iso_code
        , amount
        , max(case when status = 'ISSUED' then updated_at end)    as issued_at
        , max(case when status = 'VOID' then updated_at end)      as voided_at
    from invoices_all_states
    group by 1, 2, 3, 4, 5
)

, final_invoices_table as (
    select
        iedp.invoice_id
        , iedp.invoice_number
        , iedp.order_key
        , iedp.currency_iso_code
        , iedp.amount
        , ia.date_key           as issue_date_key
        , ia.date_key           as voided_date_key
    from invoice_event_dates_pivot iedp
    left join {{ ref('inter_dates') }} ia
        on iedp.issued_at = ia.full_date
    left join {{ ref('inter_dates') }} va
        on iedp.voided_at = va.full_date
)

, invoice_with_key as (
    select
        {{
            dbt_utils.generate_surrogate_key(
                ['invoice_id', 'invoice_number'
                ,'issue_date_key' ,'voided_date_key']
            )
        }}                         as invoice_key
        , invoice_id
        , invoice_number
        , order_key
        , issue_date_key
        , voided_date_key
        , currency_iso_code
        , amount
    from final_invoices_table
)

select * from invoice_with_key

