# SIPOR 360 - Entidades logicas dentro de datos_json

`entidades_locales` es una tabla generica: `tipo_entidad` + `id_entidad`
identifican un "modulo", y `datos_json` guarda su contenido completo. Este
documento mapea, para cada `id_entidad` usado hoy en el codigo, que
entidades de negocio contiene su JSON y de donde sale ese contrato.

## Tipos de entidad detectados (por codigo fuente)

En el `.db` real de esta maquina la tabla `entidades_locales` esta vacia
(0 filas), asi que estos valores se obtuvieron **leyendo el codigo fuente**
(no hay filas reales de negocio para muestrear todavia). Todos los
llamados a `scheduleSnapshot` / `writeSnapshot` encontrados en el proyecto
usan `tipo_entidad = 'resumen_modulo'` (fijo, definido en
`LocalDatabase.writeSnapshot`, [local_database.dart:276-282](../../lib/data/local_database.dart#L276-L282)),
variando solo el `id_entidad`:

| `id_entidad` | Modulo funcional | Definido en |
|---|---|---|
| `costos_produccion` | Productos, compras, movimientos de inventario, formulas, preparaciones, lotes, movimientos de lote, ciclos reproductivos, consumos, protocolos, mortalidades, ventas, raciones de referencia | `lib/repositories/production_cost_repository.dart:37` |
| `gestacion` | Jaulas de gestacion + maternidad 1 y 2 (resumen) + lote de sincronizacion (celo/montas) | `lib/main.dart:3045` |
| `verracos` | Registro de verracos | `lib/main.dart:2932` |
| `pre_destete` | Corrales y comederos de pre-destete | `lib/main.dart:2315` |
| `comederos_engorde` | Comederos de la etapa de engorde | `lib/main.dart:1360` |
| `comederos_parrilla` | Comederos de la etapa de parrilla | `lib/main.dart:1570` |
| `maternidad_1` | Jaulas de maternidad, galpon 1 | `lib/main.dart:3946` (`_storageKey`) |
| `maternidad_2` | Jaulas de maternidad, galpon 2 | `lib/main.dart:3946` (`_storageKey`) |

**Total: 8 valores distintos de `id_entidad`, todos bajo el mismo
`tipo_entidad = 'resumen_modulo'`.** No existe ningun otro `tipo_entidad`
en el codigo actual.

## Cantidad de registros por tipo_entidad (estado real)

| tipo_entidad | id_entidad | Filas en el .db de esta maquina |
|---|---|---|
| `resumen_modulo` | (cualquiera de los 8) | **0** |

La tabla esta vacia porque, hasta el momento de esta revision, no se ha
usado la app para registrar datos que disparen `scheduleSnapshot`/
`writeSnapshot` sobre este archivo `.db` especifico.

## Contrato JSON por modulo

### `costos_produccion`

Generado por
[lib/data/production_cost_codec.dart](../../lib/data/production_cost_codec.dart)
(`encodeProductionCostState`). Estructura de nivel superior:

```json
{
  "products": [...],
  "purchases": [...],
  "movements": [...],
  "formulas": [...],
  "preparedBatches": [...],
  "lots": [...],
  "productiveMovements": [...],
  "cycles": [...],
  "consumptions": [...],
  "protocols": [...],
  "mortalities": [...],
  "sales": [...],
  "referenceRations": [...],
  "allowNegativeStock": false,
  "defaultProfitMargin": 0.20
}
```

Ejemplo de un elemento de `products` (campos reales del codec, lineas 138-150):

```json
{
  "sync": { "idLocal": "...", "uuid": "...", "createdAt": "...", "updatedAt": "...", "synced": false, "deletedAt": null },
  "name": "Maiz molido",
  "category": "feedIngredient",
  "baseUnit": "kg",
  "controlType": "stock",
  "stock": 120.5,
  "averageCost": 3.2,
  "minimumStock": 20,
  "expirationDate": null,
  "active": true,
  "conversions": { "quintal": 46.0 }
}
```

Ejemplo de un elemento de `lots` (campos reales, lineas 347-365):

```json
{
  "sync": { "...": "..." },
  "code": "L-2026-001",
  "motherId": "cerda-014",
  "birthDate": "2026-05-10T00:00:00.000",
  "totalBorn": 12,
  "bornAlive": 11,
  "bornDead": 1,
  "weaned": 10,
  "moved": 10,
  "deadAccumulated": 0,
  "currentAnimals": 10,
  "currentStage": "preDestete",
  "currentLocation": "corral-3",
  "status": "activo",
  "costLines": [
    { "date": "...", "stage": "preDestete", "category": "feedIngredient", "description": "Alimento inicial", "amount": 45.0 }
  ],
  "totalSoldWeight": 0,
  "saleDate": null
}
```

Ejemplo de un elemento de `mortalities` (lineas 506-516):

```json
{
  "sync": { "...": "..." },
  "date": "2026-06-01T08:00:00.000",
  "lotId": "L-2026-001",
  "stage": "preDestete",
  "deadCount": 1,
  "cause": "aplastamiento",
  "note": "",
  "responsible": "Juan Perez"
}
```

Cada `Product`, `PurchaseEntry`, `InventoryMovement`, `FeedFormula`,
`PreparedFoodBatch`, `ProductionLot`, `ProductiveMovement`,
`ReproductiveCycle`, `ConsumptionRecord`, `ManagementProtocol`,
`MortalityRecord` y `SaleRecord` incluye un bloque `sync` con
`idLocal`, `uuid`, `createdAt`, `updatedAt`, `synced`, `deletedAt` — es el
unico mecanismo de identidad/borrado logico a nivel de item dentro del
JSON (no hay PK relacional real).

### `gestacion`

Generado directamente en `lib/main.dart:3076-3081`:

```json
{
  "crates": [ { "number": 1, "side": "left", "status": "confirmed", "matingDates": [...], "matingBoars": [...], "daysPregnant": 45, "expectedFarrowingDate": "..." } ],
  "maternity1": [ "...mismo formato de crate..." ],
  "maternity2": [ "...mismo formato de crate..." ],
  "synchronizationBatch": { "weaningDate": "...", "ampouleDate": "...", "heatDate": "...", "earTags": [...], "matingDates": [...] }
}
```

### `verracos`

Generado en `lib/main.dart:2941-2944`:

```json
{ "records": [ { "number": 1, "name": "Toro", "bloodline": "Duroc" } ] }
```

### `pre_destete`

Generado en `lib/main.dart:2336-2340`:

```json
{ "corrals": [ "...10 elementos, ocupacion por corral..." ], "feeders": [ "...comederos con cantidad disponible..." ] }
```

### `comederos_engorde` / `comederos_parrilla`

Mismo patron de comedero que `pre_destete.feeders`, uno por etapa
(`lib/main.dart:1360-1380` y `1570-1590`).

### `maternidad_1` / `maternidad_2`

Mismo formato de `GestationCrate` que `gestacion`, pero por galpon
individual (`lib/main.dart:3946-3982`, clase `_MaternityBarnPageState`).

## Conclusion para la nueva arquitectura (clima y precios)

Ningun modulo actual contiene, ni por asomo, columnas de clima
(`temperatura_2m_c`, `humedad_relativa_2m`, `precipitacion_mm`,
`lluvia_mm`, `fecha_hora`) ni de precios de mercado. Se confirmo por
busqueda de texto en todo `lib/` y `database/`: cero coincidencias reales
(el unico match fue la cadena de interfaz `"Control de temperatura"`, un
item de checklist sanitario sin relacion con el dataset).

Si se agrega un modulo `clima` o `precios_mercado`, el patron mas
consistente con la arquitectura actual seria crear un nuevo `id_entidad`
(por ejemplo `'clima'` o `'precios_mercado'`) bajo el mismo
`tipo_entidad = 'resumen_modulo'`, con su propio codec en
`lib/data/` siguiendo el mismo esquema que `production_cost_codec.dart`.
Esto es una recomendacion, no fue implementada.
