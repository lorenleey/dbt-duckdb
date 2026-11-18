{{ config(materialized='table') }}

select
    artist,
    count(*) as valid_plays,
    count(distinct user_id) as unique_listeners,
    round(sum(played_seconds) / 60.0, 2) as total_listening_minutes,
    round(avg(completion_pct), 1) as avg_completion_pct
from {{ ref('int_valid_streams') }}
group by artist
order by valid_plays desc, artist
