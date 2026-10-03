import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_target.dart';

Future<DatabaseTarget> createDatabaseTarget() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    final basePath = await mobile.getDatabasesPath();
    return DatabaseTarget(
      factory: mobile.databaseFactory,
      path: path.join(basePath, 'sipor360_lapampita.db'),
    );
  }

  sqfliteFfiInit();
  final supportDirectory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(
    path.join(supportDirectory.path, 'databases'),
  );
  await databaseDirectory.create(recursive: true);
  return DatabaseTarget(
    factory: databaseFactoryFfi,
    path: path.join(databaseDirectory.path, 'sipor360_lapampita.db'),
  );
}
