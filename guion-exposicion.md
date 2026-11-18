# Guion final · dbt + DuckDB

Duración objetivo: unos **43–46 minutos**, incluyendo una práctica guiada de unos 15 minutos.

## 1. Introducción

Hoy voy a hablar de dbt y de cómo podemos usarlo con DuckDB. DuckDB ya lo hemos visto como motor analítico; mi parte se centra sobre todo en dbt: qué problema resuelve, cómo organiza las transformaciones y qué aporta frente a tener simplemente una carpeta llena de SQL.

La idea importante es que **en dbt seguimos escribiendo principalmente SQL**. dbt no sustituye SQL: añade estructura, dependencias, tests, documentación y reutilización alrededor de ese SQL.

## 2. ¿Qué problema resuelve dbt?

En un proyecto pequeño podemos escribir consultas SQL sueltas y ejecutarlas manualmente. El problema aparece cuando empiezan a existir muchas transformaciones que dependen unas de otras.

Tenemos que saber qué ejecutar primero, qué tabla depende de cuál, cómo comprobar que el resultado sigue siendo válido y cómo documentar todo eso.

dbt organiza esas transformaciones como modelos y permite tratarlas como un proyecto de software.

## 3. Dónde entra dbt en ELT

En un flujo ELT primero extraemos y cargamos los datos y después transformamos dentro del motor de datos.

dbt actúa principalmente en la **T de ELT**. No es la herramienta que normalmente utilizamos para extraer datos de una API o mover millones de eventos desde Kafka. Su trabajo empieza cuando esos datos ya están disponibles en una plataforma sobre la que podemos ejecutar SQL.

## 4. Conceptos básicos

Un **modelo** es normalmente un archivo SQL que genera una vista o una tabla.

`ref()` referencia otro modelo o seed. Además de generar la referencia correcta, declara una dependencia.

`source()` se usa para referenciar datos de origen que dbt no construye.

Las **macros** son piezas reutilizables de lógica escritas con Jinja. Se parecen a funciones y sirven para no repetir lógica SQL.

Jinja es el sistema de plantillas que permite escribir expresiones como `{{ ref('modelo') }}`, configuraciones y macros dentro del SQL.

## 5. Materializaciones, tests y documentación

Un modelo puede materializarse de distintas formas. En esta demo utilizo principalmente `view` para capas intermedias y `table` para el mart final.

dbt también permite crear tests. Los tests no deciden por nosotros qué es correcto: nosotros definimos la regla de calidad y dbt la comprueba.

Además puede generar documentación y lineage a partir del propio proyecto.

## 6. DuckDB + dbt

DuckDB funciona muy bien para una demo local porque no necesito levantar un servidor ni conectarme a un warehouse cloud.

Para desarrollo local, aprendizaje, prototipos y CI es muy cómodo. En escenarios que necesitan computación distribuida, muchísima concurrencia o gobierno centralizado a gran escala normalmente entrarían otras plataformas.

## 7. Perfiles profesionales

dbt aparece especialmente en Data Engineering y Analytics Engineering. También puede ser útil para perfiles de Data Analytics que trabajan cerca de la capa de transformación.

Lo interesante es que mezcla conocimientos de SQL con buenas prácticas que normalmente asociamos al desarrollo de software: control de versiones, modularidad, tests y documentación.

# Demo StreamFlow

Ahora paso a StreamFlow, una plataforma ficticia de streaming musical.

El objetivo final es obtener métricas por artista a partir de eventos de reproducción.

## 8. Seed / raw

Primero compruebo la configuración:

```powershell
dbt debug --project-dir . --profiles-dir .
```

Después cargo la seed:

```powershell
dbt seed --profiles-dir .
dbt show --select raw_streams --profiles-dir . --limit -1
```

Explico que `dbt seed` carga un CSV pequeño como tabla. En producción los datos podrían venir de una aplicación, Kafka, Event Hubs, un lake o un warehouse; aquí utilizo una seed porque permite reproducir el caso rápidamente.

En el raw hay 13 eventos y algunos problemas intencionados: espacios, `es`, `MOBILE`, país o dispositivo vacío y un evento sin artista.

## 9. Staging

Ejecuto:

```powershell
dbt run --select stg_streams --profiles-dir .
dbt show --select stg_streams --profiles-dir . --limit -1
```

Aquí enseño qué cambia:

- espacios fuera;
- países a mayúsculas;
- dispositivos a minúsculas;
- valores vacíos no críticos pasan a `UNKNOWN` / `unknown`;
- el registro sin artista se elimina porque el mart final analiza precisamente por artista.

Pasamos de **13 a 12 registros**.

## 10. Intermediate

Ejecuto:

```powershell
dbt run --select int_valid_streams --profiles-dir .
dbt show --inline "select play_id, artist, track, played_seconds, track_duration_s, completion_pct from {{ ref('int_valid_streams') }}" --profiles-dir . --limit -1
```

Ahora aplicamos la regla de negocio: una reproducción válida debe durar al menos 30 segundos y no puede superar la duración de la canción.

Se eliminan P002, con 25 s, y P007, con 12 s. Pasamos de **12 a 10 registros**.

También calculamos `completion_pct`, el porcentaje de la canción que se reprodujo.

## 11. Mart

Ejecuto:

```powershell
dbt run --select artist_metrics --profiles-dir .
dbt show --select artist_metrics --profiles-dir . --limit -1
```

Ya no quiero eventos individuales. El mart agrupa por artista y calcula reproducciones válidas, oyentes únicos, minutos escuchados y porcentaje medio completado.

Aquí remarco que el mart está materializado como tabla.

## 12. dbt sabe el orden

Ejecuto:

```powershell
dbt run --profiles-dir .
```

Y explico que dbt sabe el orden porque cada `ref()` declara una dependencia:

```text
raw_streams
     ↓
stg_streams
     ↓
int_valid_streams
     ↓
artist_metrics
```

Eso forma un DAG. No depende del nombre de las carpetas ni del orden alfabético de los SQL.

## 13. Tests

Ejecuto:

```powershell
dbt test --profiles-dir .
```

Los tests comprueban unicidad, valores nulos, dispositivos permitidos y que `completion_pct` esté entre 0 y 100.

Puedo recordar el ejemplo que vimos durante la preparación: cuando `unknown` no estaba incluido entre los dispositivos aceptados, el test falló. Eso demuestra que dbt está comprobando exactamente la regla que nosotros definimos.

## 14. Extra: documentación + DAG visual

Termino mi demo con:

```powershell
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

Abro el lineage y enseño visualmente:

```text
raw_streams → stg_streams → int_valid_streams → artist_metrics
```

Aquí conecto con `ref()`: las mismas dependencias que dbt utilizó para decidir el orden son las que puede representar en el lineage.

## 15. Práctica guiada

Los compañeros reciben `caso-practico/`.

La seed y la configuración ya están listas. Ellos crean los tres modelos copiando el código de las instrucciones, ejecutan cada capa y entregan cinco capturas con una observación breve.

La intención no es que memoricen sintaxis, sino que vean cómo cambia el dato en cada capa y entiendan por qué.

## Cierre

dbt no sustituye SQL. Lo convierte en un proyecto más mantenible: modelos conectados por dependencias, transformaciones separadas por capas, reglas de calidad, documentación y lineage.

Y con DuckDB podemos enseñar todo esto localmente sin necesitar infraestructura externa.
