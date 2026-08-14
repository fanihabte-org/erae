with crm_account_cleaned as (
    select
        id::bigint                      as id
        , trim(name)                    as name
        , trim(accountnumber)           as account_number
        , trim(industry)                as industry
        , trim(type)                    as type
        , trim(billingcountry)          as billing_country
        , annualrevenue::decimal(19,2)  as annual_revenue
        , numberofemployees::int        as number_of_employees
        , trim(ownerid::varchar)        as owner_id
        , isdeleted::boolean            as is_deleted
        , createddate::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as create_timestamp
        , lastmodifieddate::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as update_timestamp
        , dw_run_timestamp::timestamp
              at time zone 'America/Los_Angeles'
              at time zone 'UTC'        as dw_run_timestamp
    from {{ source('salesforce', 'account') }}
)

select * from crm_account_cleaned