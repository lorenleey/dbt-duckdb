select *
from {{ ref('int_valid_streams') }}
where completion_pct < 0
   or completion_pct > 100
