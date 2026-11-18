# Caso práctico · StreamFlow con dbt + DuckDB

Tiempo orientativo: **15 minutos**.

La seed y la configuración ya están preparadas. Tu trabajo es crear los modelos indicados, ejecutar el pipeline y observar qué cambia en cada capa.

## Objetivo

Construir:

```text
raw_streams
     ↓
stg_streams
     ↓
int_valid_streams
     ↓
artist_metrics
```

Al final entregarás **5 capturas**. Debajo de cada una responde una pregunta corta con 1–3 frases.

---

## 0. Comprobar que dbt funciona

Abre una terminal dentro de `caso-practico/` y ejecuta:

```powershell
dbt debug --project-dir . --profiles-dir .
```

Debe terminar con:

```text
All checks passed!
```

---

## 1. Cargar la seed

El archivo `seeds/raw_streams.csv` ya está listo.

```powershell
dbt seed --profiles-dir .
dbt show --select raw_streams --profiles-dir . --limit -1
```

Hay 13 registros y algunos problemas intencionados: espacios, mayúsculas/minúsculas distintas, valores vacíos, una fila sin artista y reproducciones demasiado cortas.

### Captura 1 · raw_streams

**Pregunta:** mirando el raw, menciona dos problemas de calidad que encuentres. ¿Los tratarías de la misma manera?

---

## 2. Crear staging

Crea `models/staging/stg_streams.sql`:

```sql
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
```

Ejecuta:

```powershell
dbt run --select stg_streams --profiles-dir .
dbt show --select stg_streams --profiles-dir . --limit -1
```

Debes pasar de **13 a 12 filas**.

### Captura 2 · stg_streams

**Pregunta:** ¿qué dato decidimos eliminar y por qué? ¿Por qué sí conservamos una fila cuyo país o dispositivo sea desconocido?

---

## 3. Crear intermediate

Crea `models/intermediate/int_valid_streams.sql`:

```sql
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
```

Ejecuta:

```powershell
dbt run --select int_valid_streams --profiles-dir .
dbt show --inline "select play_id, artist, track, played_seconds, track_duration_s, completion_pct from {{ ref('int_valid_streams') }}" --profiles-dir . --limit -1
```

Debes pasar de **12 a 10 filas**.

### Captura 3 · int_valid_streams

**Pregunta:** ¿qué dos reproducciones desaparecieron? Explica con tus palabras qué representa `completion_pct`.

---

## 4. Crear el mart

Crea `models/marts/artist_metrics.sql`:

```sql
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
```

Ejecuta:

```powershell
dbt run --select artist_metrics --profiles-dir .
dbt show --select artist_metrics --profiles-dir . --limit -1
```

### Captura 4 · artist_metrics

**Pregunta:** ¿qué diferencia ves entre esta tabla y las capas anteriores? ¿Para qué tipo de usuario sería más útil este resultado?

---

## 5. Ejecutar el pipeline completo

```powershell
dbt run --profiles-dir .
```

Fíjate en el orden de ejecución.

**Pregunta para pensar:** ¿cómo sabe dbt qué modelo tiene que ejecutar primero? Pista: mira los `ref()`.

---

## 6. Añadir tests

Crea `models/schema.yml`:

```yaml
version: 2

models:
  - name: stg_streams
    columns:
      - name: play_id
        data_tests:
          - unique
          - not_null
      - name: artist
        data_tests:
          - not_null
      - name: device
        data_tests:
          - accepted_values:
              arguments:
                values:
                  - mobile
                  - desktop
                  - tv
                  - unknown

  - name: artist_metrics
    columns:
      - name: artist
        data_tests:
          - unique
          - not_null
```

Crea `tests/assert_completion_pct_valid.sql`:

```sql
select *
from {{ ref('int_valid_streams') }}
where completion_pct < 0
   or completion_pct > 100
```

Ejecuta:

```powershell
dbt test --profiles-dir .
```

### Captura 5 · dbt test

**Pregunta:** los tests han pasado, pero ¿significa eso que los datos son perfectos? Explica qué es realmente lo que dbt está comprobando.

---

# Entrega

Entrega las cinco capturas con la respuesta breve correspondiente:

1. `raw_streams`
2. `stg_streams`
3. `int_valid_streams`
4. `artist_metrics`
5. `dbt test`

No hace falta volver a pegar todo el código en la entrega.

## Resultado esperado

```text
raw_streams          13 filas
      ↓
stg_streams          12 filas
      ↓
int_valid_streams    10 filas
      ↓
artist_metrics
      ↓
tests
```
