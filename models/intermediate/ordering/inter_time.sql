with twenty_four_hours as (
    select
    to_char(num_seq, 'FM00')                    as time_key
    , num_seq                                   as hour_24
    , case
        when num_seq < 12 then num_seq
        when num_seq >= 12 then num_seq - 12
        end                                     as hour_12
    from generate_series(0,23) as num_seq
)

select
    *
    , case
        when hour_24 >= 12 then 'PM'
        else 'AM' end                                    as am_pm
    , case
        when hour_24 between 0 and 5 then 'Night'
        when hour_24 between 6 and 11 then 'Morning'
        when hour_24 between 12 and 17 then 'Afternoon'
        when hour_24 between 18 and 23 then 'Evening'
      end                                                as time_of_day
from twenty_four_hours