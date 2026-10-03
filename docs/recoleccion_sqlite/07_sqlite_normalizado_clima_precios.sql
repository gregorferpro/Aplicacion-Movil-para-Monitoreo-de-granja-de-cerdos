-- SIPOR 360 - Tablas normalizadas nuevas (esquema SQLite version 3)
-- Origen real: lib/data/local_database.dart, metodo _createDatasetTables()
-- Se agregan en la migracion de version 2 -> 3, SIN tocar ni borrar
-- metadatos_aplicacion, entidades_locales ni cola_sincronizacion.
--
-- Reglas aplicadas:
-- - Sin JSON: cada atributo es una columna atomica (REAL/TEXT/INTEGER).
-- - Sin CREATE INDEX, sin TRIGGER, sin VIEW, sin procedimientos.
-- - Nombres en espanol, snake_case.
-- - Claves foraneas explicitas para las relaciones "se relaciona con".
--   (No son "indices" en el sentido prohibido: son restricciones de
--   integridad referencial; SQLite las valida porque la app activa
--   PRAGMA foreign_keys = ON en cada conexion.)

-- =========================================================
-- 1. zonas
-- Zona geografica de referencia (ej. la ubicacion de la cabana).
-- Es el punto de union entre clima y mercado.
-- =========================================================
CREATE TABLE IF NOT EXISTS zonas (
  id_zona TEXT PRIMARY KEY,
  nombre_zona TEXT NOT NULL,
  departamento TEXT,
  pais TEXT
);

-- =========================================================
-- 2. fuentes_datos
-- De donde vino cada dato: Open-Meteo, precio de mercado local,
-- registro manual, etc. Evita repetir el nombre de la fuente como
-- texto libre en cada fila de clima_exterior / precios_mercado_porcino.
-- =========================================================
CREATE TABLE IF NOT EXISTS fuentes_datos (
  id_fuente TEXT PRIMARY KEY,
  nombre_fuente TEXT NOT NULL,
  tipo_fuente TEXT NOT NULL,
  descripcion TEXT
);

-- =========================================================
-- 3. clima_exterior
-- Registro climatico horario/puntual del dataset de Open-Meteo
-- (o cualquier otra fuente registrada en fuentes_datos).
-- =========================================================
CREATE TABLE IF NOT EXISTS clima_exterior (
  id_clima TEXT PRIMARY KEY,
  id_zona TEXT NOT NULL,
  id_fuente TEXT NOT NULL,
  fecha_hora TEXT NOT NULL,
  temperatura_2m_c REAL,
  humedad_relativa_2m REAL,
  precipitacion_mm REAL,
  lluvia_mm REAL,
  FOREIGN KEY (id_zona) REFERENCES zonas(id_zona),
  FOREIGN KEY (id_fuente) REFERENCES fuentes_datos(id_fuente)
);

-- =========================================================
-- 4. mercados
-- Mercado o punto de venta de referencia para precios del cerdo.
-- =========================================================
CREATE TABLE IF NOT EXISTS mercados (
  id_mercado TEXT PRIMARY KEY,
  nombre_mercado TEXT NOT NULL,
  id_zona TEXT NOT NULL,
  descripcion TEXT,
  FOREIGN KEY (id_zona) REFERENCES zonas(id_zona)
);

-- =========================================================
-- 5. precios_mercado_porcino
-- Precio historico puntual (por fecha) de un mercado.
-- =========================================================
CREATE TABLE IF NOT EXISTS precios_mercado_porcino (
  id_precio TEXT PRIMARY KEY,
  id_mercado TEXT NOT NULL,
  id_fuente TEXT NOT NULL,
  fecha TEXT NOT NULL,
  precio_kg_vivo REAL,
  precio_kg_canal REAL,
  moneda TEXT NOT NULL,
  FOREIGN KEY (id_mercado) REFERENCES mercados(id_mercado),
  FOREIGN KEY (id_fuente) REFERENCES fuentes_datos(id_fuente)
);

-- =========================================================
-- 6. indicadores_climaticos
-- Resumen mensual por zona (agregado a partir de clima_exterior).
-- Es una entidad propia con su propia clave (zona + anio + mes),
-- no un duplicado de clima_exterior: existe para consultas rapidas
-- de planificacion sin recalcular promedios sobre el detalle horario.
-- =========================================================
CREATE TABLE IF NOT EXISTS indicadores_climaticos (
  id_indicador_climatico TEXT PRIMARY KEY,
  id_zona TEXT NOT NULL,
  anio INTEGER NOT NULL,
  mes INTEGER NOT NULL,
  temperatura_promedio_c REAL,
  humedad_promedio REAL,
  precipitacion_total_mm REAL,
  lluvia_total_mm REAL,
  dias_calor_extremo INTEGER,
  dias_humedad_alta INTEGER,
  nivel_riesgo_sanitario TEXT,
  FOREIGN KEY (id_zona) REFERENCES zonas(id_zona)
);

-- =========================================================
-- 7. indicadores_mercado
-- Resumen mensual por mercado (agregado a partir de
-- precios_mercado_porcino), misma logica que indicadores_climaticos.
-- =========================================================
CREATE TABLE IF NOT EXISTS indicadores_mercado (
  id_indicador_mercado TEXT PRIMARY KEY,
  id_mercado TEXT NOT NULL,
  anio INTEGER NOT NULL,
  mes INTEGER NOT NULL,
  precio_promedio_kg_vivo REAL,
  precio_maximo_kg_vivo REAL,
  precio_minimo_kg_vivo REAL,
  tendencia TEXT,
  nivel_conveniencia TEXT,
  FOREIGN KEY (id_mercado) REFERENCES mercados(id_mercado)
);

-- =========================================================
-- 8. planificaciones_productivas
-- Una planificacion concreta (ej. "proximo ciclo de gestacion en
-- zona La Pampita") con las fechas recomendadas de monta, parto,
-- destete y venta.
-- =========================================================
CREATE TABLE IF NOT EXISTS planificaciones_productivas (
  id_planificacion TEXT PRIMARY KEY,
  id_zona TEXT NOT NULL,
  objetivo TEXT NOT NULL,
  fecha_monta_recomendada TEXT,
  fecha_parto_estimada TEXT,
  fecha_destete_estimada TEXT,
  fecha_venta_estimada TEXT,
  estado TEXT NOT NULL,
  fecha_creacion TEXT NOT NULL,
  FOREIGN KEY (id_zona) REFERENCES zonas(id_zona)
);

-- =========================================================
-- 9. recomendaciones_productivas
-- El "por que" detras de cada planificacion: los puntajes que la
-- justifican (clima, precio, salud, peso) y una explicacion en texto.
-- =========================================================
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
