# dbt + DuckDB · StreamFlow

Repositorio de apoyo para mi exposición sobre **dbt + DuckDB**.

La demo usa una plataforma ficticia de streaming musical llamada **StreamFlow**. Partimos de eventos raw, limpiamos datos, aplicamos una regla de negocio, construimos un mart de métricas por artista y terminamos validando la calidad con tests.

## Contenido

- `dbt-presentacion-lorenley.pptx` → presentación.
- `guion-exposicion.md` → guion final de la exposición y orden de la demo.
- `demo-streamflow/` → proyecto dbt completo que uso durante la demo.
- `caso-practico/` → práctica guiada para clase con seed lista e instrucciones paso a paso.

## Flujo de StreamFlow

```text
raw_streams
     ↓
stg_streams
     ↓
int_valid_streams
     ↓
artist_metrics
```

La seed contiene algunos problemas intencionados para que las transformaciones se puedan ver: espacios, mayúsculas/minúsculas inconsistentes, valores vacíos y reproducciones que no cumplen la regla de negocio.

## Qué enseña la demo

1. Cargar una seed con `dbt seed`.
2. Limpiar y normalizar datos en staging.
3. Aplicar una regla de negocio en intermediate.
4. Crear un mart analítico.
5. Entender cómo `ref()` crea dependencias y permite a dbt construir el DAG.
6. Ejecutar tests de calidad.
7. Generar documentación y visualizar el lineage.

## Tecnologías

- dbt 2.x
- DuckDB
- SQL
- Jinja

## Ejecución rápida

Desde `demo-streamflow/`:

```powershell
dbt debug --project-dir . --profiles-dir .
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

Para generar la documentación:

```powershell
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

`--profiles-dir .` indica a dbt que busque `profiles.yml` en la carpeta actual.
