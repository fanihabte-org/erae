with crm_opportunity_cleaned as (
    select
        id::bigint                       as id
        , accountid::bigint              as account_id
        , name::varchar(256)             as name
        , stagename::varchar(20)         as stage_name
        , amount::decimal(18,2)          as amount
        , currencyisocode::varchar(10)   as currency_iso_code
        , probability::int               as probability
        , leadsource::varchar(256)       as lead_source
        , campaignid::varchar(50)        as campaign_id
        , discountpercent::decimal(18,2) as discount_percent
        , lossreason::varchar(50)        as loss_reason
        , salescycledays::int            as sales_cycle_days
        , ownerid::varchar(50)           as owner_id
        , isdeleted::bool                as is_deleted
        , closedate::date                as close_date
        , createddate::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'         as create_at
        , lastmodifieddate::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'         as update_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'         as dw_run_timestamp
    from {{ source('salesforce', 'opportunity') }}
)

select * from crm_opportunity_cleaned
