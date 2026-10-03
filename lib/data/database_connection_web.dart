import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database_target.dart';

Future<DatabaseTarget> createDatabaseTarget() async {
  return DatabaseTarget(
    factory: databaseFactoryFfiWeb,
    path: 'sipor360_lapampita.db',
  );
}
