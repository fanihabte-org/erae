with erp_revenue_posting_cleaned as (
    select
        posting_id::bigint               as id
        , trim(upper(document_number))   as document_number
        , trim(upper(document_type))     as document_type
        , trim(upper(company_code))      as company_code
        , order_ref::bigint              as order_id
        , reverses_posting_id::bigint    as reverses_id
        , gl_account::bigint             as gl_account_id
        , cost_center_code               as cost_center_id
        , trim(upper(document_currency)) as document_currency_iso_code
        , trim(upper(company_currency))  as company_currency_iso_code
        , amount_doc::decimal(18,2)      as document_ammount
        , amount_company::decimal(18,2)  as company_amount
        , trim(fiscal_period)            as fiscal_period
        , posting_date::date             as posting_date
        , posted_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'         as posted_at
        , created_at
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'         as created_at
        , dw_run_timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'         as dw_run_timestamp
    from {{ source('finance', 'revenue_postings') }}
)

select * from erp_revenue_posting_cleaned