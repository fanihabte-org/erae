select
    date_key
    , full_date
    , day_name
    , month_name
    , quarter_name
    , fiscal_year
    , quarter_num
    , month_num
    , day_of_week
    , day_of_month
    , day_of_year
    , is_weekend
from {{ ref('inter_dates') }}