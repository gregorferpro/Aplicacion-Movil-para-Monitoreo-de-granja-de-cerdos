# SIPOR 360 - Esquema SQLite normalizado (clima, precios, planificacion)

Este documento explica el porque y el como de las 9 tablas nuevas
agregadas en la migracion de esquema **version 2 -> version 3** de
[lib/data/local_database.dart](../../lib/data/local_database.dart)
(metodo `_createDatasetTables`). No se elimino ni se modifico ninguna
tabla existente.

## 1. Por que se agregan tablas estructuradas

Hasta la version 2, todo el dato de negocio de SIPOR 360 vivia como texto
JSON dentro de una sola columna (`entidades_locales.datos_json`), ver
[04_entidades_json_detectadas.md](04_entidades_json_detectadas.md). Ese
modelo es rapido de programar (un solo `Map<String, dynamic>` por
modulo), pero es inservible para lo que pide este objetivo: cruzar
**series de tiempo** (clima por hora, precio por dia) contra
**produccion** (lotes, mortalidad, consumo, costos) usando SQL directo.
SQLite no puede indexar, filtrar por rango de fecha ni agregar
(`AVG`, `SUM`, `GROUP BY`) el contenido de un campo `TEXT` con JSON
embebido de forma practica.

Las tablas nuevas resuelven eso: cada atributo relevante (temperatura,
precio, fecha) es su propia columna tipada, consultable con SQL estandar
sin funciones JSON.

## 2. Diferencia entre entidades_locales (JSON) y las tablas nuevas

| | `entidades_locales` (existente) | Tablas nuevas (`zonas`, `clima_exterior`, etc.) |
|---|---|---|
| Forma | 1 fila = 1 modulo completo, contenido en `datos_json` | 1 fila = 1 hecho atomico (un registro climatico, un precio, una zona) |
| Tipado | Todo es `TEXT` (JSON sin validar) | Columnas tipadas: `TEXT`, `REAL`, `INTEGER` |
| Consultas | Requiere `json_extract`/`json_each` | `SELECT ... WHERE ... GROUP BY` directo |
| Relaciones | Ninguna (todo referenciado por `id` en texto libre dentro del JSON) | `FOREIGN KEY` reales, validadas por SQLite (`PRAGMA foreign_keys = ON`, ya activo en `initialize()`) |
| Uso previsto | Estado de pantallas/formularios de la app (offline-first) | Datasets analiticos (clima, precios) y planificacion derivada |

Ambos modelos **conviven**: la app sigue guardando lotes, consumos,
mortalidades, etc. en `entidades_locales` exactamente igual que antes.
Las tablas nuevas son un modelo relacional aparte, pensado para
alimentarse de datasets externos (Open-Meteo, precios de mercado) y para
que las pantallas futuras hagan `JOIN`/`SELECT` sobre datos de produccion
sin tener que decodificar JSON en Dart primero.

## 3. Como se cumple 1FN (Primera Forma Normal)

1FN exige atributos atomicos: ninguna columna guarda una lista ni una
estructura anidada. En las 9 tablas nuevas cada columna es un escalar
(`TEXT`, `REAL` o `INTEGER`) — por ejemplo, `clima_exterior` no tiene una
columna `mediciones` con un arreglo de valores por hora; cada hora es una
fila distinta con su propio `id_clima`. Esto contrasta directamente con
`entidades_locales.datos_json`, donde `lots` es un arreglo completo
dentro de una sola celda (eso es lo que 1FN prohibe, y por eso las tablas
nuevas no usan JSON en absoluto, como pidio el enunciado).

## 4. Como se cumple 2FN (Segunda Forma Normal)

2FN exige que todo atributo no clave dependa de **toda** la clave
primaria, no solo de una parte. Esto solo es relevante cuando la clave
primaria es compuesta (de varias columnas). Las 9 tablas nuevas usan
**clave primaria simple** (`id_zona`, `id_clima`, `id_precio`, etc., cada
una un solo campo `TEXT PRIMARY KEY`), asi que no puede existir una
dependencia parcial: cada atributo depende automaticamente de la unica
columna clave. Por eso 2FN se cumple por construccion en las 9 tablas.

## 5. Como se cumple 3FN (Tercera Forma Normal)

3FN exige que no haya dependencias transitivas: un atributo no-clave no
debe depender de otro atributo no-clave. Se aplico asi:

- `clima_exterior` no repite `nombre_zona` ni `pais` en cada fila
  climatica: solo guarda `id_zona` (clave foranea) y esos datos se
  consultan haciendo `JOIN` con `zonas`. Si `nombre_zona` cambiara,
  no hay que actualizar miles de filas de `clima_exterior`.
- `precios_mercado_porcino` no repite `nombre_mercado` ni `departamento`:
  solo guarda `id_mercado`, que apunta a `mercados`.
- `indicadores_climaticos` e `indicadores_mercado` **no son una
  violacion de 3FN** aunque sus valores se puedan calcular a partir de
  `clima_exterior`/`precios_mercado_porcino`: son una entidad distinta,
  con su propia clave natural (`id_zona` + `anio` + `mes`, o `id_mercado`
  + `anio` + `mes`), pensada como una tabla resumen/agregada para
  planificacion rapida — el mismo patron que ya usa el proyecto en el
  data warehouse de PostgreSQL (`dw.hecho_*`, ver
  `database/postgresql/002_data_warehouse_schema.sql`). Es una decision
  de diseno explicita (resumen mensual), no un dato "derivado
  innecesario": sin esta tabla, cada consulta de planificacion tendria
  que re-agregar todo el historial horario de clima o diario de precios.

## 6. Como se usa `clima_exterior`

Cada fila es una medicion puntual (tipicamente horaria, segun el dataset
de Open-Meteo) para una zona y una fuente:

```sql
INSERT INTO zonas (id_zona, nombre_zona, departamento, pais)
VALUES ('zona-lapampita', 'La Pampita', 'Santa Cruz', 'Bolivia');

INSERT INTO fuentes_datos (id_fuente, nombre_fuente, tipo_fuente, descripcion)
VALUES ('open-meteo', 'Open-Meteo', 'api_clima', 'Historico horario via API');

INSERT INTO clima_exterior
  (id_clima, id_zona, id_fuente, fecha_hora, temperatura_2m_c,
   humedad_relativa_2m, precipitacion_mm, lluvia_mm)
VALUES
  ('clima-0001', 'zona-lapampita', 'open-meteo', '2026-01-15T06:00:00',
   18.4, 82.0, 0.0, 0.0);
```

Con esto ya se puede, por ejemplo, calcular el promedio mensual (la base
de `indicadores_climaticos`):

```sql
SELECT id_zona,
       strftime('%Y', fecha_hora) AS anio,
       strftime('%m', fecha_hora) AS mes,
       AVG(temperatura_2m_c) AS temperatura_promedio,
       SUM(lluvia_mm) AS lluvia_total
FROM clima_exterior
GROUP BY id_zona, anio, mes;
```

## 7. Como se usa `precios_mercado_porcino`

Igual que `clima_exterior`, pero para el precio historico del cerdo por
mercado:

```sql
INSERT INTO mercados (id_mercado, nombre_mercado, id_zona, descripcion)
VALUES ('mercado-local', 'Mercado local La Pampita', 'zona-lapampita', 'Feria semanal');

INSERT INTO precios_mercado_porcino
  (id_precio, id_mercado, id_fuente, fecha, precio_kg_vivo, precio_kg_canal, moneda)
VALUES
  ('precio-0001', 'mercado-local', 'open-meteo', '2026-01-15', 14.5, 22.0, 'BOB');
```

Se puede consultar la tendencia reciente de precio para decidir si
conviene vender ahora o esperar (insumo de `indicadores_mercado`).

## 8. Como se usa `planificaciones_productivas`

Representa una recomendacion concreta de fechas para un objetivo dado
(ej. "iniciar un nuevo ciclo reproductivo en la zona La Pampita"):

```sql
INSERT INTO planificaciones_productivas
  (id_planificacion, id_zona, objetivo, fecha_monta_recomendada,
   fecha_parto_estimada, fecha_destete_estimada, fecha_venta_estimada,
   estado, fecha_creacion)
VALUES
  ('plan-0001', 'zona-lapampita', 'nuevo_ciclo_reproductivo',
   '2026-02-01', '2026-05-26', '2026-06-30', '2026-10-15',
   'propuesta', '2026-01-20T10:00:00');
```

Las fechas se calculan (en la logica de la app, a futuro) combinando los
plazos biologicos ya conocidos del sistema (gestacion ~114 dias, destete,
engorde) con los periodos de `indicadores_climaticos` que muestren menor
`nivel_riesgo_sanitario` y con los periodos de `indicadores_mercado` que
muestren mejor `nivel_conveniencia` para la venta.

## 9. Como se usa `recomendaciones_productivas`

Guarda el "por que" de cada `planificaciones_productivas`: un desglose de
puntajes (0-100 o 0-1, a definir) que explica la recomendacion:

```sql
INSERT INTO recomendaciones_productivas
  (id_recomendacion, id_planificacion, puntaje_clima, puntaje_precio,
   puntaje_salud, puntaje_peso, puntaje_total, explicacion, fecha_generada)
VALUES
  ('rec-0001', 'plan-0001', 0.82, 0.65, 0.90, 0.70, 0.77,
   'Temperatura estable y baja humedad en el periodo de destete; precio de mercado en alza moderada.',
   '2026-01-20T10:05:00');
```

Esto separa el **dato** (`planificaciones_productivas`, las fechas) de la
**justificacion** (`recomendaciones_productivas`, los puntajes), lo cual
tambien es una aplicacion de 3FN: si se recalculan los puntajes, no hace
falta tocar la fila de la planificacion.

## 10. Como esto ayuda a decidir mejores fechas de monta, parto, destete, engorde y venta

Con este esquema, la cadena de consulta queda asi:

1. `clima_exterior` (dato crudo, horario) se agrega a
   `indicadores_climaticos` (mensual, por zona) — permite ver que meses
   historicamente tienen menos `dias_calor_extremo` y menor
   `nivel_riesgo_sanitario`, que son los mejores para gestacion,
   maternidad y pre-destete (etapas sensibles al estres termico).
2. `precios_mercado_porcino` (dato crudo, diario) se agrega a
   `indicadores_mercado` (mensual, por mercado) — permite ver la
   `tendencia` y el `nivel_conveniencia` historico para elegir el mejor
   mes de venta.
3. `planificaciones_productivas` combina ambos indicadores con los
   plazos biologicos reales del sistema (que ya existen en
   `ProductionLot`/`ReproductiveCycle` dentro de `entidades_locales`) para
   proponer `fecha_monta_recomendada`, `fecha_parto_estimada`,
   `fecha_destete_estimada` y `fecha_venta_estimada`.
4. `recomendaciones_productivas` deja trazabilidad de por que se eligio
   esa fecha (puntaje de clima, precio, salud y peso), en vez de una
   fecha "magica" sin justificacion — util tanto para el usuario final
   como para el sustento academico del informe.

Nada de este flujo esta implementado en pantallas todavia (el enunciado
pidio explicitamente no tocar pantallas en esta fase); estas tablas son
la base de datos que ese flujo va a necesitar.
