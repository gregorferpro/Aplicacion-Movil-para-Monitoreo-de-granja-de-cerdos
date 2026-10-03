-- SIPOR 360 - SQL REAL extraido de sqlite_master
-- Base: C:\Users\asus f17\AppData\Roaming\com.example\cabana_cerdos_app\databases\sipor360_lapampita.db
-- Obtenido con:
--   SELECT type, name, tbl_name, sql FROM sqlite_master
--   WHERE type IN ('table','index','view','trigger') ORDER BY type, name;
-- No hay vistas ni triggers en esta base (0 filas de type='view' / type='trigger').
-- Este SQL es una copia literal de lo devuelto por sqlite_master, no fue
-- reescrito ni inventado.

-- =========================================================
-- CREATE TABLE reales (tal cual sqlite_master.sql)
-- =========================================================

CREATE TABLE metadatos_aplicacion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL,
        actualizado_en TEXT NOT NULL
      );

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
      );

CREATE TABLE cola_sincronizacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_entidad TEXT NOT NULL,
        id_entidad TEXT NOT NULL,
        operacion TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        creado_en TEXT NOT NULL,
        cantidad_intentos INTEGER NOT NULL DEFAULT 0,
        ultimo_error TEXT
      );

-- Tabla interna generada automaticamente por SQLite (por el
-- AUTOINCREMENT de cola_sincronizacion.id), no la crea el codigo del
-- proyecto:
-- CREATE TABLE sqlite_sequence(name,seq)

-- =========================================================
-- CREATE INDEX reales (tal cual sqlite_master.sql)
-- =========================================================

CREATE INDEX idx_entidades_estado_sincronizacion
      ON entidades_locales(estado_sincronizacion, actualizado_en);

CREATE INDEX idx_cola_sincronizacion_entidad
      ON cola_sincronizacion(tipo_entidad, id_entidad);

-- Ademas existen 2 autoindices generados por SQLite para las PK
-- (no tienen sql propio en sqlite_master, sql = NULL):
--   sqlite_autoindex_entidades_locales_1      -> PK (tipo_entidad, id_entidad)
--   sqlite_autoindex_metadatos_aplicacion_1   -> PK (clave)

-- =========================================================
-- Consultas de verificacion / diagnostico
-- =========================================================

-- Ver todo el SQL de creacion (tablas, indices, vistas, triggers)
SELECT type, name, tbl_name, sql
FROM sqlite_master
WHERE type IN ('table', 'index', 'view', 'trigger')
ORDER BY type, name;

-- Ver solo tablas
SELECT name, sql
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;

-- Ver solo indices
SELECT name, tbl_name, sql
FROM sqlite_master
WHERE type = 'index'
ORDER BY tbl_name, name;

-- Columnas de cada tabla (PRAGMA table_info)
PRAGMA table_info('metadatos_aplicacion');
PRAGMA table_info('entidades_locales');
PRAGMA table_info('cola_sincronizacion');

-- Confirmar que no hay vistas ni triggers
SELECT type, COUNT(*) FROM sqlite_master
WHERE type IN ('view', 'trigger')
GROUP BY type;

-- Confirmar que no hay foreign keys declaradas
PRAGMA foreign_key_list('metadatos_aplicacion');
PRAGMA foreign_key_list('entidades_locales');
PRAGMA foreign_key_list('cola_sincronizacion');

-- Version de esquema de la app (coincide con LocalDatabase.schemaVersion)
PRAGMA user_version;
