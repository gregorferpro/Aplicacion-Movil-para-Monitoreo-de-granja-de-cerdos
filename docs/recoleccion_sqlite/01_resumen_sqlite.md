# SIPOR 360 - Resumen de la base SQLite local

Documento generado por revision directa del codigo fuente y del archivo
`.db` real presente en esta maquina de desarrollo. No se modifico codigo,
no se borraron datos ni se ejecuto ninguna migracion para generar este
documento.

## 1. Motor SQLite usado

El proyecto declara tres paquetes en [pubspec.yaml](../../pubspec.yaml):

```yaml
sqflite: ^2.4.3
sqflite_common_ffi: ^2.4.2
sqflite_common_ffi_web: ^1.1.2
```

La seleccion es automatica segun plataforma, mediante exportacion
condicional en
[lib/data/database_connection.dart](../../lib/data/database_connection.dart):

```dart
export 'database_connection_stub.dart'
    if (dart.library.io) 'database_connection_io.dart'
    if (dart.library.js_interop) 'database_connection_web.dart';
```

| Plataforma | Motor real | Archivo que lo define |
|---|---|---|
| Android / iOS / macOS | `sqflite` (plugin nativo) | `database_connection_io.dart` (rama `Platform.isAndroid \|\| isIOS \|\| isMacOS`) |
| Windows / Linux | `sqflite_common_ffi` | `database_connection_io.dart` (rama `else`, con `sqfliteFfiInit()`) |
| Web | `sqflite_common_ffi_web` | `database_connection_web.dart` |
| Cualquier otra plataforma | error controlado | `database_connection_stub.dart` (`throw UnsupportedError`) |

En esta maquina (Windows) el motor activo es **`sqflite_common_ffi`**.

## 2. Nombre del archivo de base de datos

Constante en ambos conectores nativos:

```
sipor360_lapampita.db
```

## 3. Se crea en tiempo de ejecucion

No existe ningun `.db` versionado dentro del repositorio (se confirmo
buscando `*.db` en todo el proyecto: cero resultados). El archivo se crea
la primera vez que la app llama a `localDatabase.initialize()`
([lib/data/local_database.dart](../../lib/data/local_database.dart) lineas 23-41),
que a su vez llama a `createDatabaseTarget()` y luego
`factory.openDatabase(...)` con `onCreate: _createSchema`.

## 4. Rutas

### Windows (confirmada fisicamente en esta maquina)

```
C:\Users\asus f17\AppData\Roaming\com.example\cabana_cerdos_app\databases\sipor360_lapampita.db
```

Se genera con `getApplicationSupportDirectory()` (paquete `path_provider`)
+ subcarpeta `\databases\`
([database_connection_io.dart](../../lib/data/database_connection_io.dart) lineas 19-28).
El segmento `com.example\cabana_cerdos_app` corresponde a `CompanyName` /
`ProductName` definidos en
[windows/runner/Runner.rc](../../windows/runner/Runner.rc) (lineas 92-98),
que siguen en el valor por defecto del template de Flutter (no se
personalizaron). Si se cambia el `CompanyName`, esta ruta cambia.

Archivo verificado en disco: tamano 36864 bytes, `PRAGMA user_version = 2`
(coincide con `LocalDatabase.schemaVersion = 2` en el codigo).

### Android (emulador) - ruta probable, no verificada en este entorno

`sqflite` usa `getDatabasesPath()`, que en Android apunta al directorio de
base de datos privado de la app:

```
/data/data/com.example.cabana_cerdos_app/databases/sipor360_lapampita.db
```

El `applicationId`/`namespace` se confirmo en
`android/app/build.gradle.kts`: `com.example.cabana_cerdos_app`. Para
inspeccionarlo en un emulador se requiere `adb shell` con un build
`debuggable` (el emulador no expone `/data/data` a apps no root en release).

### Web

`sqflite_common_ffi_web` no crea un archivo `.db` en el sistema de
archivos: persiste en almacenamiento del navegador (OPFS/IndexedDB segun
el backend configurado). No aplica una "ruta de archivo" tradicional.

### Linux / macOS

- macOS entra en la misma rama que Android/iOS (usa `sqflite` con
  `getDatabasesPath()`), ruta tipica:
  `~/Library/Containers/<bundle-id>/Data/Documents/sipor360_lapampita.db`
  (segun sandboxing de macOS).
- Linux entra en la misma rama que Windows (`sqflite_common_ffi`), ruta
  tipica: `~/.local/share/<application-support>/cabana_cerdos_app/databases/sipor360_lapampita.db`
  (el nombre exacto de carpeta depende de `path_provider_linux`, no
  verificado en este entorno).

## 5. Hallazgo clave: SQLite no es relacional aqui

Solo existen 3 tablas propias (`metadatos_aplicacion`, `entidades_locales`,
`cola_sincronizacion`) mas la tabla interna `sqlite_sequence`. No hay una
tabla fisica por cada entidad de negocio (no existe `productos`,
`lotes_produccion`, etc. como tabla). Todo el dato de negocio vive como
JSON dentro de `entidades_locales.datos_json`. Ver detalle en
[02_tablas_fisicas_sqlite.md](02_tablas_fisicas_sqlite.md) y
[04_entidades_json_detectadas.md](04_entidades_json_detectadas.md).

## 6. Estado real de los datos en esta maquina (verificado)

Consulta directa al `.db` de esta maquina:

| Tabla | Filas |
|---|---|
| `metadatos_aplicacion` | 7 |
| `entidades_locales` | 0 |
| `cola_sincronizacion` | 0 |

Es decir, hoy **no hay datos de negocio guardados** (ni productos, ni
lotes, ni consumos, etc.) en este `.db` local; solo la configuracion
inicial sembrada por `_seedBoliviaMetadata()`.
