# Demo StreamFlow

Este es el proyecto que uso durante la exposición.

## Orden recomendado

```powershell
dbt debug --project-dir . --profiles-dir .

dbt seed --profiles-dir .
dbt show --select raw_streams --profiles-dir . --limit -1

dbt run --select stg_streams --profiles-dir .
dbt show --select stg_streams --profiles-dir . --limit -1

dbt run --select int_valid_streams --profiles-dir .
dbt show --inline "select play_id, artist, track, played_seconds, track_duration_s, completion_pct from {{ ref('int_valid_streams') }}" --profiles-dir . --limit -1

dbt run --select artist_metrics --profiles-dir .
dbt show --select artist_metrics --profiles-dir . --limit -1

dbt run --profiles-dir .
dbt test --profiles-dir .

dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

## Resultado esperado

- raw: 13 registros.
- staging: 12 registros; se elimina el evento sin artista.
- intermediate: 10 registros; se eliminan las reproducciones de 25 s y 12 s.
- mart: métricas por artista.
- tests: todos en PASS.

La macro de `macros/seconds_to_minutes.sql` queda como ejemplo de lógica reutilizable con Jinja; no es necesaria para que funcione el pipeline.
