with days_series as (
    select
        reporting_date::date                 as full_date
        , to_char(reporting_date,
                'Day')                       as day_name
        , to_char(reporting_date,
                'Month')                     as month_name
        , 'Q' || extract(quarter from
                       reporting_date)::text as quarter_name
        , extract(year from
                reporting_date)              as fiscal_year
        , extract(quarter from
                reporting_date)              as quarter_num
        , extract(month from
                reporting_date)              as month_num
        , extract(isodow
                from reporting_date)         as day_of_week
        , extract(day
                from reporting_date)         as day_of_month
        , extract(doy
                from reporting_date)         as day_of_year
    from generate_series('2023-01-01'::date,
                         '2040-01-01'::date,
                         '1 day'::interval) as reporting_date
)

select
    fiscal_year::text ||
    month_num::text  ||
    to_char(day_of_month, 'FM00') as date_key
    , *
    , day_of_week in (6,7)        as is_weekend
from days_series