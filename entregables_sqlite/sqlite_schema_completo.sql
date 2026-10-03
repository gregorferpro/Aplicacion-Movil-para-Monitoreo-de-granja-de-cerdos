-- ============================================================
-- SIPOR 360 - Esquema COMPLETO y REAL de la base SQLite local
-- ============================================================
-- Extraido en vivo (solo lectura) desde sqlite_master del archivo:
--   C:\Users\asus f17\AppData\Roaming\com.example\cabana_cerdos_app\databases\sipor360_lapampita.db
-- Fecha de extraccion: 2026-09-12
-- PRAGMA user_version del archivo real: 4
-- Motor: sqflite_common_ffi (rama Windows/Linux de package:sqflite +
--   sqflite_common_ffi, seleccionada en lib/data/database_connection_io.dart)
--
-- Cada CREATE TABLE / CREATE INDEX de este archivo es una copia LITERAL
-- de la columna `sql` de sqlite_master (mismo texto que devuelve
-- SELECT sql FROM sqlite_master). No se agrego, quito ni inventa
-- ninguna columna, tabla, PK, FK, UNIQUE ni DEFAULT. Los unicos anadidos
-- son los comentarios de seccion y el `;` final de cada sentencia.
--
-- No hay ninguna tabla VIEW ni TRIGGER en esta base (0 filas de esos
-- tipos en sqlite_master).
-- ============================================================


-- ============================================================
-- SECCION 1 de 3: Tablas base del motor local (existen desde la
-- version 1/2 del esquema; nunca fueron borradas ni modificadas en
-- las migraciones posteriores)
-- ============================================================

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

CREATE INDEX idx_entidades_estado_sincronizacion
      ON entidades_locales(estado_sincronizacion, actualizado_en);

CREATE INDEX idx_cola_sincronizacion_entidad
      ON cola_sincronizacion(tipo_entidad, id_entidad);

-- Nota tecnica real (verificada con PRAGMA table_info): en SQLite, una
-- columna "TEXT PRIMARY KEY" NO recibe automaticamente NOT NULL (solo
-- "INTEGER PRIMARY KEY" lo hace, por ser alias del rowid, y ni siquiera
-- ese queda marcado notnull=1 en la pragma). Por eso metadatos_aplicacion
-- SI declara "valor TEXT NOT NULL" de forma explicita en columnas que no
-- son la PK, pero su columna PK "clave" no lleva NOT NULL explicito.
-- Todas las tablas nuevas (secciones 2 y 3) siguen este mismo patron:
-- sus columnas "id_x TEXT PRIMARY KEY" no llevan NOT NULL explicito.


-- ============================================================
-- SECCION 2 de 3: Tablas de dataset de referencia (clima y precios de
-- mercado, por zona/fuente) - migracion a schema version 3
-- ============================================================

CREATE TABLE zonas (
        id_zona TEXT PRIMARY KEY,
        nombre_zona TEXT NOT NULL,
        departamento TEXT,
        pais TEXT
      );

CREATE TABLE fuentes_datos (
        id_fuente TEXT PRIMARY KEY,
        nombre_fuente TEXT NOT NULL,
        tipo_fuente TEXT NOT NULL,
        descripcion TEXT
      );

CREATE TABLE clima_exterior (
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

CREATE TABLE mercados (
        id_mercado TEXT PRIMARY KEY,
        nombre_mercado TEXT NOT NULL,
        id_zona TEXT NOT NULL,
        descripcion TEXT,
        FOREIGN KEY (id_zona) REFERENCES zonas(id_zona)
      );

CREATE TABLE precios_mercado_porcino (
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

CREATE TABLE indicadores_climaticos (
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

CREATE TABLE indicadores_mercado (
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


-- ============================================================
-- SECCION 3 de 3: Tablas OPERACIONALES LOCALES de la cabana
-- (identidad, infraestructura, animales, reproduccion, lotes,
-- inventario, alimento, consumos/mortalidades/pesajes/costos/ventas,
-- indicadores locales y planificacion) - migracion a schema version 4
-- ============================================================

CREATE TABLE cabanas (
        id_cabana TEXT PRIMARY KEY,
        nombre_cabana TEXT NOT NULL,
        propietario TEXT,
        ubicacion TEXT,
        departamento TEXT,
        pais TEXT
      );

CREATE TABLE usuarios_locales (
        id_usuario TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_completo TEXT NOT NULL,
        rol TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      );

CREATE TABLE areas_cabana (
        id_area TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_area TEXT NOT NULL,
        tipo_area TEXT NOT NULL,
        descripcion TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      );

CREATE TABLE corrales_jaulas (
        id_corral_jaula TEXT PRIMARY KEY,
        id_area TEXT NOT NULL,
        nombre_corral_jaula TEXT NOT NULL,
        tipo TEXT NOT NULL,
        capacidad_animales INTEGER,
        estado TEXT NOT NULL,
        FOREIGN KEY (id_area) REFERENCES areas_cabana(id_area)
      );

CREATE TABLE animales (
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

CREATE TABLE ciclos_reproductivos (
        id_ciclo TEXT PRIMARY KEY,
        id_cerda TEXT NOT NULL,
        fecha_inicio TEXT NOT NULL,
        estado TEXT NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_cerda) REFERENCES animales(id_animal)
      );

CREATE TABLE montas (
        id_monta TEXT PRIMARY KEY,
        id_ciclo TEXT NOT NULL,
        id_verraco TEXT,
        fecha_monta TEXT NOT NULL,
        tipo_monta TEXT,
        observacion TEXT,
        FOREIGN KEY (id_ciclo) REFERENCES ciclos_reproductivos(id_ciclo),
        FOREIGN KEY (id_verraco) REFERENCES animales(id_animal)
      );

CREATE TABLE partos (
        id_parto TEXT PRIMARY KEY,
        id_ciclo TEXT NOT NULL,
        fecha_parto TEXT NOT NULL,
        nacidos_vivos INTEGER NOT NULL,
        nacidos_muertos INTEGER NOT NULL,
        destetados INTEGER,
        observacion TEXT,
        FOREIGN KEY (id_ciclo) REFERENCES ciclos_reproductivos(id_ciclo)
      );

CREATE TABLE lotes_produccion (
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

CREATE TABLE movimientos_lote (
        id_movimiento_lote TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_movimiento TEXT NOT NULL,
        etapa_origen TEXT,
        etapa_destino TEXT,
        cantidad INTEGER NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      );

CREATE TABLE productos (
        id_producto TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_producto TEXT NOT NULL,
        categoria TEXT NOT NULL,
        unidad_base TEXT NOT NULL,
        costo_promedio REAL,
        estado TEXT NOT NULL,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      );

CREATE TABLE compras (
        id_compra TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        fecha_compra TEXT NOT NULL,
        proveedor TEXT,
        total_compra REAL NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      );

-- Tabla intermedia (asociativa): compras <-> productos
CREATE TABLE compra_detalles (
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

CREATE TABLE movimientos_inventario (
        id_movimiento_inventario TEXT PRIMARY KEY,
        id_producto TEXT NOT NULL,
        fecha_movimiento TEXT NOT NULL,
        tipo_movimiento TEXT NOT NULL,
        cantidad REAL NOT NULL,
        costo_unitario REAL,
        motivo TEXT,
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      );

CREATE TABLE formulas_alimento (
        id_formula TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_formula TEXT NOT NULL,
        etapa TEXT NOT NULL,
        estado TEXT NOT NULL,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      );

-- Tabla intermedia (asociativa): formulas_alimento <-> productos
CREATE TABLE formula_ingredientes (
        id_formula_ingrediente TEXT PRIMARY KEY,
        id_formula TEXT NOT NULL,
        id_producto TEXT NOT NULL,
        porcentaje REAL NOT NULL,
        FOREIGN KEY (id_formula) REFERENCES formulas_alimento(id_formula),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      );

CREATE TABLE preparaciones_alimento (
        id_preparacion TEXT PRIMARY KEY,
        id_formula TEXT NOT NULL,
        fecha_preparacion TEXT NOT NULL,
        cantidad_total_kg REAL NOT NULL,
        costo_total REAL NOT NULL,
        FOREIGN KEY (id_formula) REFERENCES formulas_alimento(id_formula)
      );

-- Tabla intermedia (asociativa): preparaciones_alimento <-> productos
CREATE TABLE preparacion_ingredientes (
        id_preparacion_ingrediente TEXT PRIMARY KEY,
        id_preparacion TEXT NOT NULL,
        id_producto TEXT NOT NULL,
        cantidad_kg REAL NOT NULL,
        costo_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (id_preparacion) REFERENCES preparaciones_alimento(id_preparacion),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      );

CREATE TABLE consumos (
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

CREATE TABLE mortalidades (
        id_mortalidad TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_mortalidad TEXT NOT NULL,
        cantidad_muertos INTEGER NOT NULL,
        causa TEXT,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      );

CREATE TABLE pesajes (
        id_pesaje TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_pesaje TEXT NOT NULL,
        peso_promedio_kg REAL NOT NULL,
        cantidad_animales INTEGER,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      );

CREATE TABLE costos_lote (
        id_costo_lote TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_costo TEXT NOT NULL,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      );

CREATE TABLE ventas (
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

CREATE TABLE indicadores_climaticos_locales (
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

CREATE TABLE indicadores_mercado_locales (
        id_indicador_mercado TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        anio INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        precio_promedio_kg_vivo REAL,
        tendencia TEXT,
        nivel_conveniencia TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      );

CREATE TABLE planificaciones_productivas (
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

CREATE TABLE recomendaciones_productivas (
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

-- ============================================================
-- Tabla interna de SQLite (no creada por el proyecto; aparece sola
-- por el uso de AUTOINCREMENT en cola_sincronizacion.id):
--   CREATE TABLE sqlite_sequence(name,seq)
-- ============================================================
