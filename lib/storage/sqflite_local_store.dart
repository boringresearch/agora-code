import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'local_store.dart';

class SqfliteLocalStore implements LocalStore {
  Database? _db;

  Database get db {
    final value = _db;
    if (value == null) {
      throw StateError(
          'LocalStore.init must be called before database access.');
    }
    return value;
  }

  @override
  Future<void> init() async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, 'mind_agora.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE rooms(
            id TEXT PRIMARY KEY,
            topic TEXT NOT NULL,
            background TEXT,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            room_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE memories(
            id TEXT PRIMARY KEY,
            room_id TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            tags TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX idx_messages_room_created ON messages(room_id, created_at)',
        );
      },
    );
  }

  @override
  Future<void> saveSession(RoomSession session) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'rooms',
      {
        'id': session.id,
        'topic': session.topic,
        'background': session.background,
        'payload': jsonEncode(session.toJson()),
        'created_at': session.createdAt?.millisecondsSinceEpoch ?? now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<RoomSession>> listSessions() async {
    final rows = await db.query('rooms', orderBy: 'updated_at DESC');
    return rows
        .map((row) => RoomSession.fromPayload(row['payload'] as String))
        .toList();
  }

  @override
  Future<void> saveMessage(String roomId, AgoraMessage message) async {
    await db.insert(
      'messages',
      {
        'id': message.id,
        'room_id': roomId,
        'payload': jsonEncode(message.toJson()),
        'created_at': message.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AgoraMessage>> listMessages(String roomId) async {
    final rows = await db.query(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
    );
    return rows
        .map((row) => AgoraMessage.fromJson(
              jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> readSetting(String key) async {
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
