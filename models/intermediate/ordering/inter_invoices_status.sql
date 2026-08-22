with invoices_all_states as (
    select
        {{
            dbt_utils.generate_surrogate_key (
                ['invoice_id', 'status']
            )
        }}           as invoice_status_key
        , invoice_id
        , status
        , updated_at
    from {{ ref('stg_ops_invoices') }}
)

select * from invoices_all_states