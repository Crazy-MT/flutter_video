import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class VideoLikes {
  VideoLikes({DatabaseFactory? factory, String? path})
    : _factory = factory,
      _path = path;

  final DatabaseFactory? _factory;
  final String? _path;
  Future<Database>? _database;

  Future<Database> _open() async {
    var factory = _factory;
    if (factory == null && (Platform.isWindows || Platform.isLinux)) {
      ffi.sqfliteFfiInit();
      factory = ffi.databaseFactoryFfi;
    }
    factory ??= databaseFactory;
    final path =
        _path ??
        p.join((await getApplicationSupportDirectory()).path, 'video_likes.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE video_likes (path TEXT PRIMARY KEY, count INTEGER NOT NULL DEFAULT 0 CHECK(count >= 0))',
        ),
      ),
    );
  }

  Future<Database> get database async {
    try {
      return await (_database ??= _open());
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<int> count(String path) async {
    final rows = await (await database).query(
      'video_likes',
      columns: ['count'],
      where: 'path = ?',
      whereArgs: [path],
    );
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  // shortcut: Likes belong to the file path on this device; use stable IDs for sync or moved files.
  Future<int> increment(String path) async {
    if (path.isEmpty) throw ArgumentError.value(path, 'path');
    return (await database).transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO video_likes(path, count) VALUES (?, 0)',
        [path],
      );
      await txn.rawUpdate(
        'UPDATE video_likes SET count = count + 1 WHERE path = ?',
        [path],
      );
      final rows = await txn.query(
        'video_likes',
        where: 'path = ?',
        whereArgs: [path],
      );
      return rows.first['count'] as int;
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await (await db).close();
    _database = null;
  }
}
