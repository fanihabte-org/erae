with crm_account_cleaned as (
    select
        id::bigint                      as id
        , trim(upper(ownerid))          as owner_id
        , trim(upper(name))             as name
        , trim(upper(accountnumber))    as account_number
        , trim(upper(industry))         as industry
        , trim(upper(type))             as type
        , trim(upper(billingcountry))   as billing_country
        , isdeleted::boolean            as is_deleted
        , annualrevenue::decimal(19,2)  as annual_revenue
        , numberofemployees::int        as number_of_employees
        , createddate::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as created_at
        , lastmodifieddate::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as updated_at
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as dw_run_timestamp
    from {{ source('salesforce', 'account') }}
)

select * from crm_account_cleaned