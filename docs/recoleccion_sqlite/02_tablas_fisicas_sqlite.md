# SIPOR 360 - Tablas fisicas reales de SQLite

Extraido directamente de `sqlite_master` del archivo real
`sipor360_lapampita.db` (Windows, `PRAGMA user_version = 2`) y contrastado
con [lib/data/local_database.dart](../../lib/data/local_database.dart)
(`_createSchema`, lineas 43-84). Coinciden exactamente.

## Inventario de objetos

| Tipo | Nombre | Tabla asociada |
|---|---|---|
| table | `metadatos_aplicacion` | - |
| table | `entidades_locales` | - |
| table | `cola_sincronizacion` | - |
| table | `sqlite_sequence` | interna de SQLite (por `AUTOINCREMENT`) |
| index | `idx_entidades_estado_sincronizacion` | `entidades_locales` |
| index | `idx_cola_sincronizacion_entidad` | `cola_sincronizacion` |
| index | `sqlite_autoindex_entidades_locales_1` | `entidades_locales` (PK compuesta, automatico) |
| index | `sqlite_autoindex_metadatos_aplicacion_1` | `metadatos_aplicacion` (PK, automatico) |

No hay ninguna `FOREIGN KEY` declarada en ninguna tabla (`PRAGMA
foreign_key_list` vacio para las tres). SQLite no fuerza integridad
referencial en este esquema.

---

## Tabla `metadatos_aplicacion`

**SQL CREATE original (leido de `sqlite_master`):**

```sql
CREATE TABLE metadatos_aplicacion (
  clave TEXT PRIMARY KEY,
  valor TEXT NOT NULL,
  actualizado_en TEXT NOT NULL
)
```

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `clave` | TEXT | NO | **PK** |
| `valor` | TEXT | NO | |
| `actualizado_en` | TEXT | NO | (fecha ISO8601 UTC) |

**Indices:** `sqlite_autoindex_metadatos_aplicacion_1` (automatico, sobre `clave`).

**Para que sirve:** pares clave/valor de configuracion global de la app
(moneda, zona horaria, codigo de cabana, etc.). Se siembra en
`_seedBoliviaMetadata()` ([local_database.dart](../../lib/data/local_database.dart) lineas 239-259).

**Filas reales en esta maquina (7):** `codigo_cabana`, `nombre_cabana`,
`codigo_moneda`, `simbolo_moneda`, `configuracion_regional`,
`zona_horaria`, `kilogramos_quintal`.

---

## Tabla `entidades_locales`

**SQL CREATE original:**

```sql
CREATE TABLE entidades_locales (
  tipo_entidad TEXT NOT NULL,
  id_entidad TEXT NOT NULL,
  codigo_cabana TEXT NOT NULL,
  datos_json TEXT NOT NULL,
  creado_en TEXT NOT NULL,
  actualizado_en TEXT NOT NULL,
  eliminado_en TEXT,
  estado_sincronizacion TEXT NOT NULL DEFAULT 'pendiente',
  PRIMARY KEY (tipo_entidad, id_entidad)
)
```

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `tipo_entidad` | TEXT | NO | **PK (1/2)** |
| `id_entidad` | TEXT | NO | **PK (2/2)** |
| `codigo_cabana` | TEXT | NO | |
| `datos_json` | TEXT | NO | payload de negocio completo |
| `creado_en` | TEXT | NO | |
| `actualizado_en` | TEXT | NO | |
| `eliminado_en` | TEXT | SI | borrado logico |
| `estado_sincronizacion` | TEXT | NO | default `'pendiente'` |

**Indices:**
```sql
CREATE INDEX idx_entidades_estado_sincronizacion
  ON entidades_locales(estado_sincronizacion, actualizado_en)
```
mas el autoindice de la PK compuesta.

**Para que sirve:** almacen generico tipo documento. Cada fila es un
"modulo" completo de la app guardado como JSON. Esta es la tabla que
concentra practicamente todo el dato de negocio del sistema (ver
[04_entidades_json_detectadas.md](04_entidades_json_detectadas.md)).

**Filas reales en esta maquina:** 0.

---

## Tabla `cola_sincronizacion`

**SQL CREATE original:**

```sql
CREATE TABLE cola_sincronizacion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_entidad TEXT NOT NULL,
  id_entidad TEXT NOT NULL,
  operacion TEXT NOT NULL,
  datos_json TEXT NOT NULL,
  creado_en TEXT NOT NULL,
  cantidad_intentos INTEGER NOT NULL DEFAULT 0,
  ultimo_error TEXT
)
```

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | INTEGER | NO | **PK AUTOINCREMENT** |
| `tipo_entidad` | TEXT | NO | |
| `id_entidad` | TEXT | NO | |
| `operacion` | TEXT | NO | `insertar` / `actualizar` / `eliminar` |
| `datos_json` | TEXT | NO | copia del payload en el momento del cambio |
| `creado_en` | TEXT | NO | |
| `cantidad_intentos` | INTEGER | NO | default 0 |
| `ultimo_error` | TEXT | SI | |

**Indices:**
```sql
CREATE INDEX idx_cola_sincronizacion_entidad
  ON cola_sincronizacion(tipo_entidad, id_entidad)
```

**Para que sirve:** outbox de cambios pendientes de enviar a la futura
API/PostgreSQL. Se llena automaticamente cada vez que
`upsertEntity`/`deleteEntity` corren en `entidades_locales`
(`_replaceOutboxOperation`, [local_database.dart](../../lib/data/local_database.dart) lineas 375-395).
Hoy la sincronizacion remota no esta implementada, asi que estas filas se
acumulan sin ser drenadas por ningun proceso todavia.

**Filas reales en esta maquina:** 0.

---

## Tabla interna `sqlite_sequence`

Tabla automatica de SQLite para llevar el contador de
`AUTOINCREMENT` (usada por `cola_sincronizacion.id`). No se crea
explicitamente en el codigo del proyecto; SQLite la genera sola.
