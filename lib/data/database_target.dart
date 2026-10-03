import 'package:sqflite_common/sqlite_api.dart';

class DatabaseTarget {
  const DatabaseTarget({required this.factory, required this.path});

  final DatabaseFactory factory;
  final String path;
}
