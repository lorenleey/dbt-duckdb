{{ config(materialized='view') }}

select
    trim(play_id) as play_id,
    trim(user_id) as user_id,
    trim(track_id) as track_id,
    trim(artist) as artist,
    trim(track) as track,
    cast(track_duration_s as integer) as track_duration_s,
    cast(played_seconds as integer) as played_seconds,
    coalesce(nullif(upper(trim(country)), ''), 'UNKNOWN') as country,
    coalesce(nullif(lower(trim(device)), ''), 'unknown') as device,
    cast(played_at as timestamp) as played_at
from {{ ref('raw_streams') }}
where artist is not null
  and trim(artist) <> ''
