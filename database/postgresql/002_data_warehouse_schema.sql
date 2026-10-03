BEGIN;

CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE IF NOT EXISTS dw.dim_fecha (
  fecha_key integer PRIMARY KEY,
  fecha date NOT NULL UNIQUE,
  anio smallint NOT NULL,
  trimestre smallint NOT NULL,
  mes smallint NOT NULL,
  nombre_mes varchar(20) NOT NULL,
  semana smallint NOT NULL,
  dia smallint NOT NULL,
  dia_semana smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_granja (
  granja_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  codigo varchar(40) NOT NULL,
  nombre varchar(150) NOT NULL,
  departamento varchar(100),
  municipio varchar(100),
  activa boolean NOT NULL,
  valido_desde timestamptz NOT NULL DEFAULT now(),
  valido_hasta timestamptz,
  es_actual boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS dw.dim_etapa (
  etapa_key smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo varchar(30) NOT NULL UNIQUE,
  nombre varchar(80) NOT NULL,
  orden smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_producto (
  producto_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  granja_uuid uuid NOT NULL,
  codigo varchar(50) NOT NULL,
  nombre varchar(160) NOT NULL,
  categoria varchar(40) NOT NULL,
  subcategoria varchar(80),
  unidad_base varchar(20) NOT NULL,
  activo boolean NOT NULL,
  valido_desde timestamptz NOT NULL DEFAULT now(),
  valido_hasta timestamptz,
  es_actual boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS dw.dim_lote (
  lote_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  granja_uuid uuid NOT NULL,
  codigo varchar(60) NOT NULL,
  madre_uuid uuid,
  fecha_nacimiento date NOT NULL,
  etapa_actual varchar(30) NOT NULL,
  estado varchar(30) NOT NULL,
  valido_desde timestamptz NOT NULL DEFAULT now(),
  valido_hasta timestamptz,
  es_actual boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS dw.hecho_costos_lote (
  costo_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  fecha_key integer NOT NULL REFERENCES dw.dim_fecha(fecha_key),
  granja_key bigint NOT NULL REFERENCES dw.dim_granja(granja_key),
  lote_key bigint NOT NULL REFERENCES dw.dim_lote(lote_key),
  etapa_key smallint REFERENCES dw.dim_etapa(etapa_key),
  categoria varchar(40) NOT NULL,
  descripcion varchar(250) NOT NULL,
  origen_tipo varchar(40) NOT NULL,
  costo numeric(16,4) NOT NULL CHECK (costo >= 0),
  cargado_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.hecho_consumos (
  consumo_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  fecha_key integer NOT NULL REFERENCES dw.dim_fecha(fecha_key),
  granja_key bigint NOT NULL REFERENCES dw.dim_granja(granja_key),
  lote_key bigint REFERENCES dw.dim_lote(lote_key),
  producto_key bigint NOT NULL REFERENCES dw.dim_producto(producto_key),
  etapa_key smallint REFERENCES dw.dim_etapa(etapa_key),
  tipo_destino varchar(20) NOT NULL,
  cantidad_base numeric(16,4) NOT NULL,
  costo_unitario numeric(16,6) NOT NULL,
  costo_total numeric(16,4) NOT NULL,
  animales_atendidos integer,
  cargado_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.hecho_movimientos_inventario (
  movimiento_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  fecha_key integer NOT NULL REFERENCES dw.dim_fecha(fecha_key),
  granja_key bigint NOT NULL REFERENCES dw.dim_granja(granja_key),
  producto_key bigint NOT NULL REFERENCES dw.dim_producto(producto_key),
  tipo varchar(20) NOT NULL,
  cantidad numeric(16,4) NOT NULL,
  costo_unitario numeric(16,6) NOT NULL,
  costo_total numeric(16,4) NOT NULL,
  stock_posterior numeric(16,4),
  cargado_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.hecho_mortalidad (
  mortalidad_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  fecha_key integer NOT NULL REFERENCES dw.dim_fecha(fecha_key),
  granja_key bigint NOT NULL REFERENCES dw.dim_granja(granja_key),
  lote_key bigint NOT NULL REFERENCES dw.dim_lote(lote_key),
  etapa_key smallint REFERENCES dw.dim_etapa(etapa_key),
  cantidad_muertos integer NOT NULL,
  causa varchar(200),
  cargado_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.hecho_ventas (
  venta_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  origen_uuid uuid NOT NULL UNIQUE,
  fecha_key integer NOT NULL REFERENCES dw.dim_fecha(fecha_key),
  granja_key bigint NOT NULL REFERENCES dw.dim_granja(granja_key),
  lote_key bigint NOT NULL REFERENCES dw.dim_lote(lote_key),
  animales_vendidos integer NOT NULL,
  peso_total_kg numeric(16,4) NOT NULL,
  peso_promedio_kg numeric(16,4) NOT NULL,
  precio_por_kg numeric(16,4) NOT NULL,
  total_venta numeric(16,4) NOT NULL,
  cargado_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.hecho_lote_snapshot (
  snapshot_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fecha_key integer NOT NULL REFERENCES dw.dim_fecha(fecha_key),
  granja_key bigint NOT NULL REFERENCES dw.dim_granja(granja_key),
  lote_key bigint NOT NULL REFERENCES dw.dim_lote(lote_key),
  etapa_key smallint REFERENCES dw.dim_etapa(etapa_key),
  animales_actuales integer NOT NULL,
  muertos_acumulados integer NOT NULL,
  costo_acumulado numeric(16,4) NOT NULL,
  peso_total_vendido_kg numeric(16,4) NOT NULL,
  cargado_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (fecha_key, lote_key)
);

INSERT INTO dw.dim_etapa (codigo, nombre, orden)
VALUES
  ('gestacion', 'Gestacion', 1),
  ('maternidad', 'Maternidad', 2),
  ('pre_destete', 'Pre-destete', 3),
  ('parrilla', 'Parrilla / Crecimiento', 4),
  ('engorde', 'Engorde', 5),
  ('venta', 'Venta', 6),
  ('verracos', 'Verracos', 7),
  ('otro', 'Otro', 99)
ON CONFLICT (codigo) DO UPDATE
SET nombre = EXCLUDED.nombre,
    orden = EXCLUDED.orden;

CREATE OR REPLACE PROCEDURE dw.refrescar_desde_operacional()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO dw.dim_fecha (
    fecha_key,
    fecha,
    anio,
    trimestre,
    mes,
    nombre_mes,
    semana,
    dia,
    dia_semana
  )
  SELECT DISTINCT
    to_char(f.fecha, 'YYYYMMDD')::integer,
    f.fecha,
    extract(year FROM f.fecha)::smallint,
    extract(quarter FROM f.fecha)::smallint,
    extract(month FROM f.fecha)::smallint,
    trim(to_char(f.fecha, 'TMMonth')),
    extract(week FROM f.fecha)::smallint,
    extract(day FROM f.fecha)::smallint,
    extract(isodow FROM f.fecha)::smallint
  FROM (
    SELECT fecha::date FROM operacional.costos_lote WHERE deleted_at IS NULL
    UNION
    SELECT fecha::date FROM operacional.consumos WHERE deleted_at IS NULL
    UNION
    SELECT fecha::date FROM operacional.movimientos_inventario WHERE deleted_at IS NULL
    UNION
    SELECT fecha::date FROM operacional.mortalidades WHERE deleted_at IS NULL
    UNION
    SELECT fecha::date FROM operacional.ventas WHERE deleted_at IS NULL
    UNION
    SELECT CURRENT_DATE
  ) AS f
  ON CONFLICT (fecha_key) DO NOTHING;

  INSERT INTO dw.dim_granja (
    origen_uuid,
    codigo,
    nombre,
    departamento,
    municipio,
    activa
  )
  SELECT id, codigo, nombre, departamento, municipio, activa
  FROM operacional.granjas
  WHERE deleted_at IS NULL
  ON CONFLICT (origen_uuid) DO UPDATE
  SET codigo = EXCLUDED.codigo,
      nombre = EXCLUDED.nombre,
      departamento = EXCLUDED.departamento,
      municipio = EXCLUDED.municipio,
      activa = EXCLUDED.activa,
      es_actual = true,
      valido_hasta = NULL;

  INSERT INTO dw.dim_producto (
    origen_uuid,
    granja_uuid,
    codigo,
    nombre,
    categoria,
    subcategoria,
    unidad_base,
    activo
  )
  SELECT
    id,
    granja_id,
    codigo,
    nombre,
    categoria,
    subcategoria,
    unidad_base,
    activo
  FROM operacional.productos
  WHERE deleted_at IS NULL
  ON CONFLICT (origen_uuid) DO UPDATE
  SET codigo = EXCLUDED.codigo,
      nombre = EXCLUDED.nombre,
      categoria = EXCLUDED.categoria,
      subcategoria = EXCLUDED.subcategoria,
      unidad_base = EXCLUDED.unidad_base,
      activo = EXCLUDED.activo,
      es_actual = true,
      valido_hasta = NULL;

  INSERT INTO dw.dim_lote (
    origen_uuid,
    granja_uuid,
    codigo,
    madre_uuid,
    fecha_nacimiento,
    etapa_actual,
    estado
  )
  SELECT
    id,
    granja_id,
    codigo,
    madre_id,
    fecha_nacimiento,
    etapa_actual,
    estado
  FROM operacional.lotes_produccion
  WHERE deleted_at IS NULL
  ON CONFLICT (origen_uuid) DO UPDATE
  SET codigo = EXCLUDED.codigo,
      madre_uuid = EXCLUDED.madre_uuid,
      etapa_actual = EXCLUDED.etapa_actual,
      estado = EXCLUDED.estado,
      es_actual = true,
      valido_hasta = NULL;

  INSERT INTO dw.hecho_costos_lote (
    origen_uuid,
    fecha_key,
    granja_key,
    lote_key,
    etapa_key,
    categoria,
    descripcion,
    origen_tipo,
    costo
  )
  SELECT
    c.id,
    to_char(c.fecha::date, 'YYYYMMDD')::integer,
    dg.granja_key,
    dl.lote_key,
    COALESCE(de.etapa_key, otro.etapa_key),
    c.categoria,
    c.descripcion,
    c.origen_tipo,
    c.costo
  FROM operacional.costos_lote c
  JOIN dw.dim_granja dg ON dg.origen_uuid = c.granja_id
  JOIN dw.dim_lote dl ON dl.origen_uuid = c.lote_id
  LEFT JOIN dw.dim_etapa de ON de.codigo = lower(replace(c.etapa, '-', '_'))
  CROSS JOIN dw.dim_etapa otro
  WHERE c.deleted_at IS NULL
    AND otro.codigo = 'otro'
  ON CONFLICT (origen_uuid) DO UPDATE
  SET fecha_key = EXCLUDED.fecha_key,
      granja_key = EXCLUDED.granja_key,
      lote_key = EXCLUDED.lote_key,
      etapa_key = EXCLUDED.etapa_key,
      categoria = EXCLUDED.categoria,
      descripcion = EXCLUDED.descripcion,
      origen_tipo = EXCLUDED.origen_tipo,
      costo = EXCLUDED.costo,
      cargado_at = now();

  INSERT INTO dw.hecho_consumos (
    origen_uuid,
    fecha_key,
    granja_key,
    lote_key,
    producto_key,
    etapa_key,
    tipo_destino,
    cantidad_base,
    costo_unitario,
    costo_total,
    animales_atendidos
  )
  SELECT
    c.id,
    to_char(c.fecha::date, 'YYYYMMDD')::integer,
    dg.granja_key,
    dl.lote_key,
    dp.producto_key,
    COALESCE(de.etapa_key, otro.etapa_key),
    c.tipo_destino,
    c.cantidad_base,
    c.costo_unitario,
    c.costo_total,
    c.animales_atendidos
  FROM operacional.consumos c
  JOIN dw.dim_granja dg ON dg.origen_uuid = c.granja_id
  JOIN dw.dim_producto dp ON dp.origen_uuid = c.producto_id
  LEFT JOIN dw.dim_lote dl ON dl.origen_uuid = c.lote_id
  LEFT JOIN dw.dim_etapa de ON de.codigo = lower(replace(c.etapa, '-', '_'))
  CROSS JOIN dw.dim_etapa otro
  WHERE c.deleted_at IS NULL
    AND otro.codigo = 'otro'
  ON CONFLICT (origen_uuid) DO UPDATE
  SET fecha_key = EXCLUDED.fecha_key,
      granja_key = EXCLUDED.granja_key,
      lote_key = EXCLUDED.lote_key,
      producto_key = EXCLUDED.producto_key,
      etapa_key = EXCLUDED.etapa_key,
      tipo_destino = EXCLUDED.tipo_destino,
      cantidad_base = EXCLUDED.cantidad_base,
      costo_unitario = EXCLUDED.costo_unitario,
      costo_total = EXCLUDED.costo_total,
      animales_atendidos = EXCLUDED.animales_atendidos,
      cargado_at = now();

  INSERT INTO dw.hecho_movimientos_inventario (
    origen_uuid,
    fecha_key,
    granja_key,
    producto_key,
    tipo,
    cantidad,
    costo_unitario,
    costo_total,
    stock_posterior
  )
  SELECT
    m.id,
    to_char(m.fecha::date, 'YYYYMMDD')::integer,
    dg.granja_key,
    dp.producto_key,
    m.tipo,
    m.cantidad,
    m.costo_unitario,
    m.costo_total,
    m.stock_posterior
  FROM operacional.movimientos_inventario m
  JOIN dw.dim_granja dg ON dg.origen_uuid = m.granja_id
  JOIN dw.dim_producto dp ON dp.origen_uuid = m.producto_id
  WHERE m.deleted_at IS NULL
  ON CONFLICT (origen_uuid) DO UPDATE
  SET fecha_key = EXCLUDED.fecha_key,
      granja_key = EXCLUDED.granja_key,
      producto_key = EXCLUDED.producto_key,
      tipo = EXCLUDED.tipo,
      cantidad = EXCLUDED.cantidad,
      costo_unitario = EXCLUDED.costo_unitario,
      costo_total = EXCLUDED.costo_total,
      stock_posterior = EXCLUDED.stock_posterior,
      cargado_at = now();

  INSERT INTO dw.hecho_mortalidad (
    origen_uuid,
    fecha_key,
    granja_key,
    lote_key,
    etapa_key,
    cantidad_muertos,
    causa
  )
  SELECT
    m.id,
    to_char(m.fecha::date, 'YYYYMMDD')::integer,
    dg.granja_key,
    dl.lote_key,
    COALESCE(de.etapa_key, otro.etapa_key),
    m.cantidad_muertos,
    m.causa
  FROM operacional.mortalidades m
  JOIN dw.dim_granja dg ON dg.origen_uuid = m.granja_id
  JOIN dw.dim_lote dl ON dl.origen_uuid = m.lote_id
  LEFT JOIN dw.dim_etapa de ON de.codigo = lower(replace(m.etapa, '-', '_'))
  CROSS JOIN dw.dim_etapa otro
  WHERE m.deleted_at IS NULL
    AND otro.codigo = 'otro'
  ON CONFLICT (origen_uuid) DO UPDATE
  SET fecha_key = EXCLUDED.fecha_key,
      granja_key = EXCLUDED.granja_key,
      lote_key = EXCLUDED.lote_key,
      etapa_key = EXCLUDED.etapa_key,
      cantidad_muertos = EXCLUDED.cantidad_muertos,
      causa = EXCLUDED.causa,
      cargado_at = now();

  INSERT INTO dw.hecho_ventas (
    origen_uuid,
    fecha_key,
    granja_key,
    lote_key,
    animales_vendidos,
    peso_total_kg,
    peso_promedio_kg,
    precio_por_kg,
    total_venta
  )
  SELECT
    v.id,
    to_char(v.fecha::date, 'YYYYMMDD')::integer,
    dg.granja_key,
    dl.lote_key,
    v.animales_vendidos,
    v.peso_total_kg,
    v.peso_promedio_kg,
    v.precio_por_kg,
    v.total_venta
  FROM operacional.ventas v
  JOIN dw.dim_granja dg ON dg.origen_uuid = v.granja_id
  JOIN dw.dim_lote dl ON dl.origen_uuid = v.lote_id
  WHERE v.deleted_at IS NULL
  ON CONFLICT (origen_uuid) DO UPDATE
  SET fecha_key = EXCLUDED.fecha_key,
      granja_key = EXCLUDED.granja_key,
      lote_key = EXCLUDED.lote_key,
      animales_vendidos = EXCLUDED.animales_vendidos,
      peso_total_kg = EXCLUDED.peso_total_kg,
      peso_promedio_kg = EXCLUDED.peso_promedio_kg,
      precio_por_kg = EXCLUDED.precio_por_kg,
      total_venta = EXCLUDED.total_venta,
      cargado_at = now();

  INSERT INTO dw.hecho_lote_snapshot (
    fecha_key,
    granja_key,
    lote_key,
    etapa_key,
    animales_actuales,
    muertos_acumulados,
    costo_acumulado,
    peso_total_vendido_kg
  )
  SELECT
    to_char(CURRENT_DATE, 'YYYYMMDD')::integer,
    dg.granja_key,
    dl.lote_key,
    COALESCE(de.etapa_key, otro.etapa_key),
    l.animales_actuales,
    l.muertos_acumulados,
    COALESCE(costos.costo_total, 0),
    l.peso_total_vendido_kg
  FROM operacional.lotes_produccion l
  JOIN dw.dim_granja dg ON dg.origen_uuid = l.granja_id
  JOIN dw.dim_lote dl ON dl.origen_uuid = l.id
  LEFT JOIN dw.dim_etapa de
    ON de.codigo = lower(replace(l.etapa_actual, '-', '_'))
  LEFT JOIN (
    SELECT lote_id, sum(costo) AS costo_total
    FROM operacional.costos_lote
    WHERE deleted_at IS NULL
    GROUP BY lote_id
  ) costos ON costos.lote_id = l.id
  CROSS JOIN dw.dim_etapa otro
  WHERE l.deleted_at IS NULL
    AND otro.codigo = 'otro'
  ON CONFLICT (fecha_key, lote_key) DO UPDATE
  SET etapa_key = EXCLUDED.etapa_key,
      animales_actuales = EXCLUDED.animales_actuales,
      muertos_acumulados = EXCLUDED.muertos_acumulados,
      costo_acumulado = EXCLUDED.costo_acumulado,
      peso_total_vendido_kg = EXCLUDED.peso_total_vendido_kg,
      cargado_at = now();
END;
$$;

CREATE OR REPLACE VIEW dw.vw_resultado_por_lote AS
WITH costos AS (
  SELECT
    lote_key,
    sum(costo) AS costo_total
  FROM dw.hecho_costos_lote
  GROUP BY lote_key
),
ventas AS (
  SELECT
    lote_key,
    sum(animales_vendidos) AS animales_vendidos,
    sum(peso_total_kg) AS peso_total_kg,
    sum(total_venta) AS ingreso_total
  FROM dw.hecho_ventas
  GROUP BY lote_key
)
SELECT
  dg.codigo AS codigo_granja,
  dg.nombre AS granja,
  dl.codigo AS lote,
  dl.fecha_nacimiento,
  dl.estado,
  COALESCE(c.costo_total, 0) AS costo_total,
  COALESCE(v.animales_vendidos, 0) AS animales_vendidos,
  COALESCE(v.peso_total_kg, 0) AS peso_total_kg,
  CASE
    WHEN COALESCE(v.peso_total_kg, 0) = 0 THEN 0
    ELSE COALESCE(c.costo_total, 0) / v.peso_total_kg
  END AS costo_por_kg,
  COALESCE(v.ingreso_total, 0) AS ingreso_total,
  COALESCE(v.ingreso_total, 0) - COALESCE(c.costo_total, 0) AS utilidad
FROM dw.dim_lote dl
JOIN dw.dim_granja dg ON dg.origen_uuid = dl.granja_uuid
LEFT JOIN costos c ON c.lote_key = dl.lote_key
LEFT JOIN ventas v ON v.lote_key = dl.lote_key
WHERE dl.es_actual;

CREATE OR REPLACE VIEW dw.vw_costo_ponderado_sector AS
SELECT
  CASE
    WHEN COALESCE(sum(peso_total_kg), 0) = 0 THEN 0
    ELSE COALESCE(sum(costo_total), 0) / sum(peso_total_kg)
  END AS costo_ponderado_por_kg,
  COALESCE(sum(costo_total), 0) AS costos_totales,
  COALESCE(sum(peso_total_kg), 0) AS kilos_totales,
  count(*) FILTER (WHERE peso_total_kg > 0) AS lotes_vendidos
FROM dw.vw_resultado_por_lote
WHERE peso_total_kg > 0;

CREATE OR REPLACE VIEW dw.vw_costo_por_etapa AS
SELECT
  dg.nombre AS granja,
  dl.codigo AS lote,
  de.nombre AS etapa,
  sum(hc.costo) AS costo_total
FROM dw.hecho_costos_lote hc
JOIN dw.dim_granja dg ON dg.granja_key = hc.granja_key
JOIN dw.dim_lote dl ON dl.lote_key = hc.lote_key
LEFT JOIN dw.dim_etapa de ON de.etapa_key = hc.etapa_key
GROUP BY dg.nombre, dl.codigo, de.nombre;

CREATE INDEX IF NOT EXISTS idx_dw_costos_lote
  ON dw.hecho_costos_lote (lote_key, fecha_key);
CREATE INDEX IF NOT EXISTS idx_dw_consumos_producto
  ON dw.hecho_consumos (producto_key, fecha_key);
CREATE INDEX IF NOT EXISTS idx_dw_ventas_lote
  ON dw.hecho_ventas (lote_key, fecha_key);
CREATE INDEX IF NOT EXISTS idx_dw_mortalidad_lote
  ON dw.hecho_mortalidad (lote_key, fecha_key);

COMMIT;

-- Ejecutar cuando se desee actualizar los reportes:
-- CALL dw.refrescar_desde_operacional();
