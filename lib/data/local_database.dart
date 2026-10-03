import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'database_connection.dart';

final LocalDatabase localDatabase = LocalDatabase._();

class LocalDatabase {
  LocalDatabase._();

  static const int schemaVersion = 4;
  static const String farmCode = 'LA_PAMPITA';

  Database? _database;
  String? _databasePath;
  Future<void> _writeQueue = Future<void>.value();

  bool get isReady => _database?.isOpen ?? false;
  String? get databasePath => _databasePath;

  Future<void> initialize() async {
    if (isReady) return;

    final target = await createDatabaseTarget();
    _databasePath = target.path;
    _database = await target.factory.openDatabase(
      target.path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    await _seedBoliviaMetadata();
    debugPrint('SQLite ready: $target');
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE metadatos_aplicacion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL,
        actualizado_en TEXT NOT NULL
      )
    ''');
    await database.execute('''
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
    ''');
    await database.execute('''
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
    ''');
    await database.execute('''
      CREATE INDEX idx_entidades_estado_sincronizacion
      ON entidades_locales(estado_sincronizacion, actualizado_en)
    ''');
    await database.execute('''
      CREATE INDEX idx_cola_sincronizacion_entidad
      ON cola_sincronizacion(tipo_entidad, id_entidad)
    ''');
    await _createDatasetTables(database);
    await _createOperationalTables(database);
  }

  Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateSchemaToSpanish(database);
    }
    if (oldVersion < 3) {
      await _createDatasetTables(database);
    }
    if (oldVersion < 4) {
      await _createOperationalTables(database);
    }
  }

  /// Tablas normalizadas (sin JSON) para los datasets de referencia de
  /// clima y precios de mercado: zonas, fuentes_datos, clima_exterior,
  /// mercados, precios_mercado_porcino, indicadores_climaticos e
  /// indicadores_mercado. Se crean con IF NOT EXISTS porque este metodo
  /// se invoca tanto para bases nuevas (onCreate) como para bases
  /// existentes en version 2 (onUpgrade), sin tocar metadatos_aplicacion,
  /// entidades_locales ni cola_sincronizacion.
  ///
  /// planificaciones_productivas y recomendaciones_productivas NO viven
  /// aqui: se movieron a _createOperationalTables (version 4) con clave
  /// foranea a cabanas en vez de zonas, para quedar alineadas con el
  /// resto del modelo operacional local. Esta tabla nunca llego a
  /// crearse en un dispositivo real (la app seguia en version 2), asi
  /// que no hubo perdida de datos al redefinirla.
  Future<void> _createDatasetTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS zonas (
        id_zona TEXT PRIMARY KEY,
        nombre_zona TEXT NOT NULL,
        departamento TEXT,
        pais TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS fuentes_datos (
        id_fuente TEXT PRIMARY KEY,
        nombre_fuente TEXT NOT NULL,
        tipo_fuente TEXT NOT NULL,
        descripcion TEXT
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS mercados (
        id_mercado TEXT PRIMARY KEY,
        nombre_mercado TEXT NOT NULL,
        id_zona TEXT NOT NULL,
        descripcion TEXT,
        FOREIGN KEY (id_zona) REFERENCES zonas(id_zona)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
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
      )
    ''');
  }

  /// Tablas normalizadas (sin JSON) del modelo operacional local de la
  /// cabana: cabana, usuarios, areas/corrales, animales, reproduccion,
  /// lotes de produccion, inventario/alimento, consumos, mortalidades,
  /// pesajes, costos, ventas, indicadores locales resumidos y la
  /// planificacion/recomendacion productiva (ahora referenciada por
  /// cabana en vez de zona). Estos datos se generan y consultan sin
  /// internet en el dispositivo; el detalle historico completo de clima
  /// y precios vive en PostgreSQL/Data Warehouse, no aqui.
  Future<void> _createOperationalTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS cabanas (
        id_cabana TEXT PRIMARY KEY,
        nombre_cabana TEXT NOT NULL,
        propietario TEXT,
        ubicacion TEXT,
        departamento TEXT,
        pais TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS usuarios_locales (
        id_usuario TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_completo TEXT NOT NULL,
        rol TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS areas_cabana (
        id_area TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_area TEXT NOT NULL,
        tipo_area TEXT NOT NULL,
        descripcion TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS corrales_jaulas (
        id_corral_jaula TEXT PRIMARY KEY,
        id_area TEXT NOT NULL,
        nombre_corral_jaula TEXT NOT NULL,
        tipo TEXT NOT NULL,
        capacidad_animales INTEGER,
        estado TEXT NOT NULL,
        FOREIGN KEY (id_area) REFERENCES areas_cabana(id_area)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS ciclos_reproductivos (
        id_ciclo TEXT PRIMARY KEY,
        id_cerda TEXT NOT NULL,
        fecha_inicio TEXT NOT NULL,
        estado TEXT NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_cerda) REFERENCES animales(id_animal)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS montas (
        id_monta TEXT PRIMARY KEY,
        id_ciclo TEXT NOT NULL,
        id_verraco TEXT,
        fecha_monta TEXT NOT NULL,
        tipo_monta TEXT,
        observacion TEXT,
        FOREIGN KEY (id_ciclo) REFERENCES ciclos_reproductivos(id_ciclo),
        FOREIGN KEY (id_verraco) REFERENCES animales(id_animal)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS partos (
        id_parto TEXT PRIMARY KEY,
        id_ciclo TEXT NOT NULL,
        fecha_parto TEXT NOT NULL,
        nacidos_vivos INTEGER NOT NULL,
        nacidos_muertos INTEGER NOT NULL,
        destetados INTEGER,
        observacion TEXT,
        FOREIGN KEY (id_ciclo) REFERENCES ciclos_reproductivos(id_ciclo)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS movimientos_lote (
        id_movimiento_lote TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_movimiento TEXT NOT NULL,
        etapa_origen TEXT,
        etapa_destino TEXT,
        cantidad INTEGER NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS productos (
        id_producto TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_producto TEXT NOT NULL,
        categoria TEXT NOT NULL,
        unidad_base TEXT NOT NULL,
        costo_promedio REAL,
        estado TEXT NOT NULL,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS compras (
        id_compra TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        fecha_compra TEXT NOT NULL,
        proveedor TEXT,
        total_compra REAL NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS movimientos_inventario (
        id_movimiento_inventario TEXT PRIMARY KEY,
        id_producto TEXT NOT NULL,
        fecha_movimiento TEXT NOT NULL,
        tipo_movimiento TEXT NOT NULL,
        cantidad REAL NOT NULL,
        costo_unitario REAL,
        motivo TEXT,
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS formulas_alimento (
        id_formula TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        nombre_formula TEXT NOT NULL,
        etapa TEXT NOT NULL,
        estado TEXT NOT NULL,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS formula_ingredientes (
        id_formula_ingrediente TEXT PRIMARY KEY,
        id_formula TEXT NOT NULL,
        id_producto TEXT NOT NULL,
        porcentaje REAL NOT NULL,
        FOREIGN KEY (id_formula) REFERENCES formulas_alimento(id_formula),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS preparaciones_alimento (
        id_preparacion TEXT PRIMARY KEY,
        id_formula TEXT NOT NULL,
        fecha_preparacion TEXT NOT NULL,
        cantidad_total_kg REAL NOT NULL,
        costo_total REAL NOT NULL,
        FOREIGN KEY (id_formula) REFERENCES formulas_alimento(id_formula)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS preparacion_ingredientes (
        id_preparacion_ingrediente TEXT PRIMARY KEY,
        id_preparacion TEXT NOT NULL,
        id_producto TEXT NOT NULL,
        cantidad_kg REAL NOT NULL,
        costo_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (id_preparacion) REFERENCES preparaciones_alimento(id_preparacion),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS mortalidades (
        id_mortalidad TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_mortalidad TEXT NOT NULL,
        cantidad_muertos INTEGER NOT NULL,
        causa TEXT,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS pesajes (
        id_pesaje TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_pesaje TEXT NOT NULL,
        peso_promedio_kg REAL NOT NULL,
        cantidad_animales INTEGER,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS costos_lote (
        id_costo_lote TEXT PRIMARY KEY,
        id_lote TEXT NOT NULL,
        fecha_costo TEXT NOT NULL,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_lote) REFERENCES lotes_produccion(id_lote)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS indicadores_mercado_locales (
        id_indicador_mercado TEXT PRIMARY KEY,
        id_cabana TEXT NOT NULL,
        anio INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        precio_promedio_kg_vivo REAL,
        tendencia TEXT,
        nivel_conveniencia TEXT,
        FOREIGN KEY (id_cabana) REFERENCES cabanas(id_cabana)
      )
    ''');
    await database.execute('''
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
      )
    ''');
    await database.execute('''
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
      )
    ''');
  }

  Future<void> _migrateSchemaToSpanish(Database database) async {
    await database.execute('''
      CREATE TABLE metadatos_aplicacion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL,
        actualizado_en TEXT NOT NULL
      )
    ''');
    await database.execute('''
      INSERT INTO metadatos_aplicacion (clave, valor, actualizado_en)
      SELECT
        CASE key
          WHEN 'farm_code' THEN 'codigo_cabana'
          WHEN 'farm_name' THEN 'nombre_cabana'
          WHEN 'currency_code' THEN 'codigo_moneda'
          WHEN 'currency_symbol' THEN 'simbolo_moneda'
          WHEN 'locale' THEN 'configuracion_regional'
          WHEN 'timezone' THEN 'zona_horaria'
          WHEN 'quintal_kg' THEN 'kilogramos_quintal'
          ELSE key
        END,
        value,
        updated_at
      FROM app_metadata
    ''');

    await database.execute('''
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
    ''');
    await database.execute('''
      INSERT INTO entidades_locales (
        tipo_entidad,
        id_entidad,
        codigo_cabana,
        datos_json,
        creado_en,
        actualizado_en,
        eliminado_en,
        estado_sincronizacion
      )
      SELECT
        CASE entity_type
          WHEN 'module_snapshot' THEN 'resumen_modulo'
          ELSE entity_type
        END,
        CASE entity_id
          WHEN 'boars' THEN 'verracos'
          WHEN 'feeders_engorde' THEN 'comederos_engorde'
          WHEN 'feeders_parrilla' THEN 'comederos_parrilla'
          WHEN 'gestation' THEN 'gestacion'
          WHEN 'maternity_1' THEN 'maternidad_1'
          WHEN 'maternity_2' THEN 'maternidad_2'
          WHEN 'production_costs' THEN 'costos_produccion'
          ELSE entity_id
        END,
        farm_code,
        payload_json,
        created_at,
        updated_at,
        deleted_at,
        CASE sync_state
          WHEN 'pending' THEN 'pendiente'
          WHEN 'synced' THEN 'sincronizado'
          ELSE sync_state
        END
      FROM local_entities
    ''');

    await database.execute('''
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
    ''');
    await database.execute('''
      INSERT INTO cola_sincronizacion (
        id,
        tipo_entidad,
        id_entidad,
        operacion,
        datos_json,
        creado_en,
        cantidad_intentos,
        ultimo_error
      )
      SELECT
        id,
        CASE entity_type
          WHEN 'module_snapshot' THEN 'resumen_modulo'
          ELSE entity_type
        END,
        CASE entity_id
          WHEN 'boars' THEN 'verracos'
          WHEN 'feeders_engorde' THEN 'comederos_engorde'
          WHEN 'feeders_parrilla' THEN 'comederos_parrilla'
          WHEN 'gestation' THEN 'gestacion'
          WHEN 'maternity_1' THEN 'maternidad_1'
          WHEN 'maternity_2' THEN 'maternidad_2'
          WHEN 'production_costs' THEN 'costos_produccion'
          ELSE entity_id
        END,
        CASE operation
          WHEN 'insert' THEN 'insertar'
          WHEN 'update' THEN 'actualizar'
          WHEN 'delete' THEN 'eliminar'
          ELSE operation
        END,
        payload_json,
        created_at,
        attempt_count,
        last_error
      FROM sync_outbox
    ''');

    await database.execute('DROP TABLE sync_outbox');
    await database.execute('DROP TABLE local_entities');
    await database.execute('DROP TABLE app_metadata');
    await database.execute('''
      CREATE INDEX idx_entidades_estado_sincronizacion
      ON entidades_locales(estado_sincronizacion, actualizado_en)
    ''');
    await database.execute('''
      CREATE INDEX idx_cola_sincronizacion_entidad
      ON cola_sincronizacion(tipo_entidad, id_entidad)
    ''');
  }

  Future<void> _seedBoliviaMetadata() async {
    final now = DateTime.now().toUtc().toIso8601String();
    const values = <String, String>{
      'codigo_cabana': farmCode,
      'nombre_cabana': 'Cabana La Pampita',
      'codigo_moneda': 'BOB',
      'simbolo_moneda': 'Bs',
      'configuracion_regional': 'es_BO',
      'zona_horaria': 'America/La_Paz',
      'kilogramos_quintal': '46',
    };
    final batch = _requireDatabase().batch();
    for (final entry in values.entries) {
      batch.insert('metadatos_aplicacion', <String, Object?>{
        'clave': entry.key,
        'valor': entry.value,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> readSnapshot(String moduleKey) async {
    if (!isReady) return null;
    final rows = await _requireDatabase().query(
      'entidades_locales',
      columns: const ['datos_json'],
      where: 'tipo_entidad = ? AND id_entidad = ? AND eliminado_en IS NULL',
      whereArgs: ['resumen_modulo', moduleKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final payload = rows.first['datos_json'];
    if (payload is! String || payload.isEmpty) return null;
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  Future<void> writeSnapshot(String moduleKey, Map<String, dynamic> payload) {
    return upsertEntity(
      entityType: 'resumen_modulo',
      entityId: moduleKey,
      payload: payload,
    );
  }

  void scheduleSnapshot(String moduleKey, Map<String, dynamic> payload) {
    if (!isReady) return;
    _writeQueue = _writeQueue
        .then((_) => writeSnapshot(moduleKey, payload))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Could not persist $moduleKey in SQLite: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  }

  Future<void> flushPendingWrites() => _writeQueue;

  Future<List<Map<String, dynamic>>> readEntities(String entityType) async {
    final rows = await _requireDatabase().query(
      'entidades_locales',
      columns: const ['datos_json'],
      where: 'tipo_entidad = ? AND eliminado_en IS NULL',
      whereArgs: [entityType],
      orderBy: 'actualizado_en ASC',
    );
    return rows
        .map((row) => jsonDecode(row['datos_json']! as String))
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<void> upsertEntity({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final database = _requireDatabase();
    final payloadJson = jsonEncode(payload);
    final now = DateTime.now().toUtc().toIso8601String();
    await database.transaction((transaction) async {
      final existing = await transaction.query(
        'entidades_locales',
        columns: const ['creado_en'],
        where: 'tipo_entidad = ? AND id_entidad = ?',
        whereArgs: [entityType, entityId],
        limit: 1,
      );
      await transaction.insert('entidades_locales', <String, Object?>{
        'tipo_entidad': entityType,
        'id_entidad': entityId,
        'codigo_cabana': farmCode,
        'datos_json': payloadJson,
        'creado_en': existing.isEmpty ? now : existing.first['creado_en'],
        'actualizado_en': now,
        'eliminado_en': null,
        'estado_sincronizacion': 'pendiente',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _replaceOutboxOperation(
        transaction,
        entityType: entityType,
        entityId: entityId,
        operation: existing.isEmpty ? 'insertar' : 'actualizar',
        payloadJson: payloadJson,
        createdAt: now,
      );
    });
  }

  Future<void> deleteEntity({
    required String entityType,
    required String entityId,
  }) async {
    final database = _requireDatabase();
    final now = DateTime.now().toUtc().toIso8601String();
    await database.transaction((transaction) async {
      await transaction.update(
        'entidades_locales',
        <String, Object?>{
          'eliminado_en': now,
          'actualizado_en': now,
          'estado_sincronizacion': 'pendiente',
        },
        where: 'tipo_entidad = ? AND id_entidad = ?',
        whereArgs: [entityType, entityId],
      );
      await _replaceOutboxOperation(
        transaction,
        entityType: entityType,
        entityId: entityId,
        operation: 'eliminar',
        payloadJson: '{}',
        createdAt: now,
      );
    });
  }

  Future<void> _replaceOutboxOperation(
    Transaction transaction, {
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    required String createdAt,
  }) async {
    await transaction.delete(
      'cola_sincronizacion',
      where: 'tipo_entidad = ? AND id_entidad = ?',
      whereArgs: [entityType, entityId],
    );
    await transaction.insert('cola_sincronizacion', <String, Object?>{
      'tipo_entidad': entityType,
      'id_entidad': entityId,
      'operacion': operation,
      'datos_json': payloadJson,
      'creado_en': createdAt,
    });
  }

  Future<int> pendingSyncCount() async {
    final result = await _requireDatabase().rawQuery(
      'SELECT COUNT(*) AS total FROM cola_sincronizacion',
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Database _requireDatabase() {
    final database = _database;
    if (database == null || !database.isOpen) {
      throw StateError('SQLite has not been initialized.');
    }
    return database;
  }
}
