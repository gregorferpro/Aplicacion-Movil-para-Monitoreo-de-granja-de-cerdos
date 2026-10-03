-- SIPOR 360 - Consultas de revision de la base SQLite local
-- Archivo: sipor360_lapampita.db
-- Uso recomendado: DB Browser for SQLite, pestana "Execute SQL".
-- Todas las consultas son de solo lectura (SELECT / PRAGMA). No incluye
-- ningun UPDATE, DELETE ni DROP.

-- =========================================================
-- 1. Ver tablas fisicas
-- =========================================================
SELECT name, type
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;

-- =========================================================
-- 2. Ver el SQL CREATE original de cada tabla e indice
-- =========================================================
SELECT type, name, tbl_name, sql
FROM sqlite_master
ORDER BY type, name;

-- =========================================================
-- 3. Ver columnas de cada tabla
-- =========================================================
PRAGMA table_info(metadatos_aplicacion);
PRAGMA table_info(entidades_locales);
PRAGMA table_info(cola_sincronizacion);

-- =========================================================
-- 4. Ver indices por tabla
-- =========================================================
PRAGMA index_list(metadatos_aplicacion);
PRAGMA index_list(entidades_locales);
PRAGMA index_list(cola_sincronizacion);

-- =========================================================
-- 5. Contar registros por tabla
-- =========================================================
SELECT 'metadatos_aplicacion' AS tabla, COUNT(*) AS filas FROM metadatos_aplicacion
UNION ALL
SELECT 'entidades_locales', COUNT(*) FROM entidades_locales
UNION ALL
SELECT 'cola_sincronizacion', COUNT(*) FROM cola_sincronizacion;

-- =========================================================
-- 6. Ver tipos de entidad y cantidad de registros por tipo
-- (hoy solo existe el tipo 'resumen_modulo'; esta consulta
-- sirve para verificarlo cada vez que se agregue mas data)
-- =========================================================
SELECT tipo_entidad, id_entidad, COUNT(*) AS registros
FROM entidades_locales
WHERE eliminado_en IS NULL
GROUP BY tipo_entidad, id_entidad
ORDER BY tipo_entidad, id_entidad;

-- Resumen agrupado solo por tipo_entidad
SELECT tipo_entidad, COUNT(*) AS registros
FROM entidades_locales
WHERE eliminado_en IS NULL
GROUP BY tipo_entidad;

-- =========================================================
-- 7. Ver metadatos de la app
-- =========================================================
SELECT clave, valor, actualizado_en
FROM metadatos_aplicacion
ORDER BY clave;

-- =========================================================
-- 8. Ver un modulo completo (ejemplo generico de datos_json)
-- Cambiar 'costos_produccion' por el id_entidad que se
-- quiera inspeccionar: gestacion, verracos, pre_destete,
-- comederos_engorde, comederos_parrilla, maternidad_1,
-- maternidad_2, costos_produccion
-- =========================================================
SELECT tipo_entidad, id_entidad, codigo_cabana, creado_en, actualizado_en,
       estado_sincronizacion, json_pretty(datos_json) AS datos_json_legible
FROM entidades_locales
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 9. Buscar productos (dentro del modulo costos_produccion)
-- =========================================================
SELECT json_extract(p.value, '$.name')        AS nombre,
       json_extract(p.value, '$.category')    AS categoria,
       json_extract(p.value, '$.baseUnit')    AS unidad_base,
       json_extract(p.value, '$.stock')       AS stock,
       json_extract(p.value, '$.averageCost') AS costo_promedio
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.products')) AS p
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 10. Buscar compras
-- =========================================================
SELECT json_extract(c.value, '$.date')             AS fecha,
       json_extract(c.value, '$.supplier')         AS proveedor,
       json_extract(c.value, '$.productName')      AS producto,
       json_extract(c.value, '$.purchasedQuantity')AS cantidad,
       json_extract(c.value, '$.totalPrice')       AS precio_total
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.purchases')) AS c
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 11. Buscar lotes de produccion
-- =========================================================
SELECT json_extract(l.value, '$.code')           AS codigo_lote,
       json_extract(l.value, '$.motherId')       AS madre_id,
       json_extract(l.value, '$.birthDate')      AS fecha_nacimiento,
       json_extract(l.value, '$.currentStage')   AS etapa_actual,
       json_extract(l.value, '$.currentAnimals') AS animales_actuales,
       json_extract(l.value, '$.status')         AS estado
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.lots')) AS l
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 12. Buscar consumos
-- =========================================================
SELECT json_extract(co.value, '$.date')       AS fecha,
       json_extract(co.value, '$.target')     AS destino,
       json_extract(co.value, '$.productName')AS producto,
       json_extract(co.value, '$.lotId')      AS lote_id,
       json_extract(co.value, '$.totalCost')  AS costo_total
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.consumptions')) AS co
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 13. Buscar mortalidades
-- =========================================================
SELECT json_extract(m.value, '$.date')     AS fecha,
       json_extract(m.value, '$.lotId')    AS lote_id,
       json_extract(m.value, '$.stage')    AS etapa,
       json_extract(m.value, '$.deadCount')AS cantidad_muertos,
       json_extract(m.value, '$.cause')    AS causa
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.mortalities')) AS m
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 14. Buscar ventas
-- =========================================================
SELECT json_extract(v.value, '$.date')        AS fecha,
       json_extract(v.value, '$.lotId')       AS lote_id,
       json_extract(v.value, '$.soldAnimals') AS animales_vendidos,
       json_extract(v.value, '$.totalWeight') AS peso_total,
       json_extract(v.value, '$.pricePerKg')  AS precio_por_kg,
       json_extract(v.value, '$.totalSale')   AS total_venta
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.sales')) AS v
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 15. Buscar costos (costLines dentro de cada lote)
-- =========================================================
SELECT json_extract(l.value, '$.code') AS codigo_lote,
       json_extract(cl.value, '$.date')        AS fecha,
       json_extract(cl.value, '$.stage')       AS etapa,
       json_extract(cl.value, '$.category')    AS categoria,
       json_extract(cl.value, '$.description') AS descripcion,
       json_extract(cl.value, '$.amount')      AS monto
FROM entidades_locales,
     json_each(json_extract(datos_json, '$.lots')) AS l,
     json_each(json_extract(l.value, '$.costLines')) AS cl
WHERE tipo_entidad = 'resumen_modulo' AND id_entidad = 'costos_produccion';

-- =========================================================
-- 16. Buscar clima (RegistroClima) - NO EXISTE HOY
-- Se deja la consulta preparada para cuando se integre el
-- dataset de Open-Meteo. Hoy devuelve 0 filas porque no hay
-- ningun modulo 'clima' ni columnas de clima en el proyecto.
-- =========================================================
SELECT tipo_entidad, id_entidad
FROM entidades_locales
WHERE id_entidad LIKE '%clima%'
   OR id_entidad LIKE '%weather%'
   OR datos_json LIKE '%temperatura_2m_c%'
   OR datos_json LIKE '%precipitacion_mm%';

-- =========================================================
-- 17. Ver cola de sincronizacion pendiente
-- =========================================================
SELECT tipo_entidad, id_entidad, operacion, cantidad_intentos, ultimo_error, creado_en
FROM cola_sincronizacion
ORDER BY creado_en DESC;
