{{ config(materialized='view') }}

select
    *,
    round(
        100.0 * played_seconds / track_duration_s,
        1
    ) as completion_pct
from {{ ref('stg_streams') }}
where played_seconds >= 30
  and played_seconds <= track_duration_s
