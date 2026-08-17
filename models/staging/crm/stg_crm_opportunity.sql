with crm_opportunity_cleaned as (
    select
        id::bigint                       as id
        , accountid::bigint              as account_id
        , trim(upper(ownerid))           as owner_id
        , trim(upper(campaignid))        as campaign_id
        , trim(upper(name))              as name
        , trim(upper(stagename))         as stage_name
        , trim(upper(lossreason))        as loss_reason
        , trim(upper(leadsource))        as lead_source
        , trim(upper(currencyisocode))   as currency_iso_code
        , salescycledays::int            as sales_cycle_days
        , isdeleted::bool                as is_deleted
        , discountpercent::decimal(18,2) as discount_percent
        , probability::int               as probability
        , amount::decimal(18,2)          as amount
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
