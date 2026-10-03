-- SIPOR 360 - Tablas normalizadas del modelo OPERACIONAL LOCAL (version 4)
-- Origen real: lib/data/local_database.dart, metodo _createOperationalTables()
-- Se agregan en la migracion de version 3 -> version 4, SIN tocar ni
-- borrar metadatos_aplicacion, entidades_locales ni cola_sincronizacion.
--
-- Alcance: datos LOCALES de una cabana especifica para trabajar offline
-- (animales, reproduccion, lotes, inventario, consumos, mortalidades,
-- pesajes, costos, ventas) mas indicadores locales resumidos y la
-- planificacion/recomendacion productiva de esa cabana. El detalle
-- historico completo de clima y de precios de mercado NO vive aqui:
-- va principalmente a PostgreSQL y al Data Warehouse (ver
-- database/postgresql/002_data_warehouse_schema.sql). Aqui solo quedan
-- indicadores_climaticos_locales / indicadores_mercado_locales, un
-- resumen mensual liviano para que la planificacion funcione sin
-- internet.
--
-- Reglas aplicadas: sin JSON, sin CREATE INDEX, sin TRIGGER, sin VIEW,
-- nombres en espanol snake_case, atributos simples, 1FN/2FN/3FN.

-- =========================================================
-- Identidad de la cabana y usuarios
-- =========================================================
CREATE TABLE IF NOT EXISTS cabanas (
  id_cabana TEXT PRIMARY KEY,
  nombre_cabana TEXT NOT NULL,
  propietario TEXT,
  ubicacion TEXT,
  departamento TEXT,
  pais TEXT
);

CREATE TABLE IF NOT EXISTS usuarios_locales (
  id_usuario TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  nombre_completo TEXT NOT NULL,
  rol TEXT NOT NULL,
  telefono TEXT,
  correo TEXT,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

-- =========================================================
-- Infraestructura fisica: areas y corrales/jaulas
-- =========================================================
CREATE TABLE IF NOT EXISTS areas_cabana (
  id_area TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  nombre_area TEXT NOT NULL,
  tipo_area TEXT NOT NULL,
  descripcion TEXT,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS corrales_jaulas (
  id_corral_jaula TEXT PRIMARY KEY,
  id_area TEXT NOT NULL,
  nombre_corral_jaula TEXT NOT NULL,
  tipo TEXT NOT NULL,
  capacidad_animales INTEGER,
  estado TEXT NOT NULL,
  FOREIGN KEY (id_area) REFERENCES areas_cabana(id_area)
);

-- =========================================================
-- Animales y reproduccion
-- =========================================================
CREATE TABLE IF NOT EXISTS animales (
  id_animal TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  codigo_animal TEXT NOT NULL,
  tipo_animal TEXT NOT NULL,
  sexo TEXT NOT NULL,
  raza TEXT,
  fecha_nacimiento TEXT,
  estado TEXT NOT NULL,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS ciclos_reproductivos (
  id_ciclo TEXT PRIMARY KEY,
  id_cerda TEXT NOT NULL,
  fecha_inicio TEXT NOT NULL,
  estado TEXT NOT NULL,
  observacion TEXT,
  FOREIGN KEY (id_cerda) REFERENCES animales(id_animal)
);

CREATE TABLE IF NOT EXISTS montas (
  id_monta TEXT PRIMARY KEY,
  id_ciclo TEXT NOT NULL,
  id_verraco TEXT,
  fecha_monta TEXT NOT NULL,
  tipo_monta TEXT,
  observacion TEXT,
  FOREIGN KEY (id_ciclo) REFERENCES ciclos_reproductivos(id_ciclo),
  FOREIGN KEY (id_verraco) REFERENCES animales(id_animal)
);

CREATE TABLE IF NOT EXISTS partos (
  id_parto TEXT PRIMARY KEY,
  id_ciclo TEXT NOT NULL,
  fecha_parto TEXT NOT NULL,
  nacidos_vivos INTEGER NOT NULL,
  nacidos_muertos INTEGER NOT NULL,
  destetados INTEGER,
  observacion TEXT,
  FOREIGN KEY (id_ciclo) REFERENCES ciclos_reproductivos(id_ciclo)
);

-- =========================================================
-- Lotes de produccion y sus movimientos
-- =========================================================
CREATE TABLE IF NOT EXISTS lotes_produccion (
  id_lote TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  codigo_lote TEXT NOT NULL,
  etapa TEXT NOT NULL,
  fecha_inicio TEXT NOT NULL,
  cantidad_inicial INTEGER NOT NULL,
  cantidad_actual INTEGER NOT NULL,
  peso_promedio_inicial_kg REAL,
  estado TEXT NOT NULL,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS movimientos_lote (
  id_movimiento_lote TEXT PRIMARY KEY,
  id_lote TEXT NOT NULL,
  fecha_movimiento TEXT NOT NULL,
  etapa_origen TEXT,
  etapa_destino TEXT,
  cantidad INTEGER NOT NULL,
  observacion TEXT,
  FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
);

-- =========================================================
-- Inventario: productos, compras y movimientos
-- =========================================================
CREATE TABLE IF NOT EXISTS productos (
  id_producto TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  nombre_producto TEXT NOT NULL,
  categoria TEXT NOT NULL,
  unidad_base TEXT NOT NULL,
  costo_promedio REAL,
  estado TEXT NOT NULL,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS compras (
  id_compra TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  fecha_compra TEXT NOT NULL,
  proveedor TEXT,
  total_compra REAL NOT NULL,
  observacion TEXT,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS compra_detalles (
  id_detalle_compra TEXT PRIMARY KEY,
  id_compra TEXT NOT NULL,
  id_producto TEXT NOT NULL,
  cantidad REAL NOT NULL,
  unidad TEXT NOT NULL,
  precio_unitario REAL NOT NULL,
  subtotal REAL NOT NULL,
  FOREIGN KEY (id_compra) REFERENCES compras(id_compra),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE IF NOT EXISTS movimientos_inventario (
  id_movimiento_inventario TEXT PRIMARY KEY,
  id_producto TEXT NOT NULL,
  fecha_movimiento TEXT NOT NULL,
  tipo_movimiento TEXT NOT NULL,
  cantidad REAL NOT NULL,
  costo_unitario REAL,
  motivo TEXT,
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- =========================================================
-- Formulas y preparaciones de alimento
-- =========================================================
CREATE TABLE IF NOT EXISTS formulas_alimento (
  id_formula TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  nombre_formula TEXT NOT NULL,
  etapa TEXT NOT NULL,
  estado TEXT NOT NULL,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS formula_ingredientes (
  id_formula_ingrediente TEXT PRIMARY KEY,
  id_formula TEXT NOT NULL,
  id_producto TEXT NOT NULL,
  porcentaje REAL NOT NULL,
  FOREIGN KEY (id_formula) REFERENCES formulas_alimento(id_formula),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE IF NOT EXISTS preparaciones_alimento (
  id_preparacion TEXT PRIMARY KEY,
  id_formula TEXT NOT NULL,
  fecha_preparacion TEXT NOT NULL,
  cantidad_total_kg REAL NOT NULL,
  costo_total REAL NOT NULL,
  FOREIGN KEY (id_formula) REFERENCES formulas_alimento(id_formula)
);

CREATE TABLE IF NOT EXISTS preparacion_ingredientes (
  id_preparacion_ingrediente TEXT PRIMARY KEY,
  id_preparacion TEXT NOT NULL,
  id_producto TEXT NOT NULL,
  cantidad_kg REAL NOT NULL,
  costo_unitario REAL NOT NULL,
  subtotal REAL NOT NULL,
  FOREIGN KEY (id_preparacion) REFERENCES preparaciones_alimento(id_preparacion),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- =========================================================
-- Consumos, mortalidades, pesajes, costos y ventas
-- =========================================================
CREATE TABLE IF NOT EXISTS consumos (
  id_consumo TEXT PRIMARY KEY,
  id_lote TEXT NOT NULL,
  id_producto TEXT NOT NULL,
  fecha_consumo TEXT NOT NULL,
  cantidad REAL NOT NULL,
  unidad TEXT NOT NULL,
  costo_total REAL,
  observacion TEXT,
  FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE IF NOT EXISTS mortalidades (
  id_mortalidad TEXT PRIMARY KEY,
  id_lote TEXT NOT NULL,
  fecha_mortalidad TEXT NOT NULL,
  cantidad_muertos INTEGER NOT NULL,
  causa TEXT,
  observacion TEXT,
  FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
);

CREATE TABLE IF NOT EXISTS pesajes (
  id_pesaje TEXT PRIMARY KEY,
  id_lote TEXT NOT NULL,
  fecha_pesaje TEXT NOT NULL,
  peso_promedio_kg REAL NOT NULL,
  cantidad_animales INTEGER,
  observacion TEXT,
  FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
);

CREATE TABLE IF NOT EXISTS costos_lote (
  id_costo_lote TEXT PRIMARY KEY,
  id_lote TEXT NOT NULL,
  fecha_costo TEXT NOT NULL,
  concepto TEXT NOT NULL,
  monto REAL NOT NULL,
  observacion TEXT,
  FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
);

CREATE TABLE IF NOT EXISTS ventas (
  id_venta TEXT PRIMARY KEY,
  id_lote TEXT NOT NULL,
  fecha_venta TEXT NOT NULL,
  cantidad_animales INTEGER NOT NULL,
  peso_total_kg REAL,
  precio_kg REAL,
  total_venta REAL NOT NULL,
  comprador TEXT,
  observacion TEXT,
  FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
);

-- =========================================================
-- Indicadores locales resumidos (livianos, mensuales, por cabana)
-- Distintos de indicadores_climaticos / indicadores_mercado (version 3),
-- que son por zona/mercado para el dataset completo en PostgreSQL/DW.
-- Estos son el resumen minimo que necesita el dispositivo offline.
-- =========================================================
CREATE TABLE IF NOT EXISTS indicadores_climaticos_locales (
  id_indicador_climatico TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  anio INTEGER NOT NULL,
  mes INTEGER NOT NULL,
  temperatura_promedio_c REAL,
  humedad_promedio REAL,
  lluvia_total_mm REAL,
  nivel_riesgo_sanitario TEXT,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS indicadores_mercado_locales (
  id_indicador_mercado TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  anio INTEGER NOT NULL,
  mes INTEGER NOT NULL,
  precio_promedio_kg_vivo REAL,
  tendencia TEXT,
  nivel_conveniencia TEXT,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

-- =========================================================
-- Planificacion y recomendacion productiva (por cabana)
-- NOTA: planificaciones_productivas y recomendaciones_productivas
-- estaban originalmente en la migracion version 3 con clave foranea
-- a zonas(id_zona). Se movieron aqui (version 4) con clave foranea a
-- cabanas(id_cabana) porque este pedido las redefine con ese alcance.
-- La version anterior nunca llego a crearse en un dispositivo real
-- (la app seguia en schema version 2), asi que no hubo perdida de
-- datos al redefinirlas.
-- =========================================================
CREATE TABLE IF NOT EXISTS planificaciones_productivas (
  id_planificacion TEXT PRIMARY KEY,
  id_cabana TEXT NOT NULL,
  objetivo TEXT NOT NULL,
  fecha_monta_recomendada TEXT,
  fecha_parto_estimada TEXT,
  fecha_destete_estimada TEXT,
  fecha_venta_estimada TEXT,
  estado TEXT NOT NULL,
  fecha_creacion TEXT NOT NULL,
  FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
);

CREATE TABLE IF NOT EXISTS recomendaciones_productivas (
  id_recomendacion TEXT PRIMARY KEY,
  id_planificacion TEXT NOT NULL,
  puntaje_clima REAL,
  puntaje_precio REAL,
  puntaje_salud REAL,
  puntaje_peso REAL,
  puntaje_total REAL,
  explicacion TEXT,
  fecha_generada TEXT NOT NULL,
  FOREIGN KEY (id_planificacion) REFERENCES planificaciones_productivas(id_planificacion)
);
