{% snapshot  }

with customer as (
    select
        soc.id
        , soc.name
        , soc.segment
        , soc.industry
        , soc.country
        , soc.region
        , soc.is_active
        , soc.created_at
        , soc.updated_at
        , soc.dw_run_timestamp
    from {{ ref('stg_ops_customers') }} soc
    left join {{ ref('stg_crm_account') }} sca
        on soc.account_number = sca.account_number
)

select * from customer