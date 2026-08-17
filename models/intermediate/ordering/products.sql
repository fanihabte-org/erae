with products as (
    select
        id
        , sku
        , name
        , category
        , family
        , price_usd
        , cost_usd
        , discontinued_on
        , case
            when is_discontinued is true then False
            else true end as  is_active
        , launch_date
        , created_at
        , updated_at
        , dw_run_timestamp
    from {{ ref('stg_ops_products') }}
)

select * from products