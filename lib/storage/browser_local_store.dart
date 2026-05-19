import 'dart:convert';
import 'dart:html' as html;

import '../models/models.dart';
import 'local_store.dart';

class BrowserLocalStore implements LocalStore {
  static const _roomsKey = 'mind_agora.rooms.v1';
  static const _settingsKey = 'mind_agora.settings.v1';
  static const _messagePrefix = 'mind_agora.messages.';

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(RoomSession session) async {
    final rows = _readRows(_roomsKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = <String, Object?>{
      'id': session.id,
      'payload': jsonEncode(session.toJson()),
      'created_at': session.createdAt?.millisecondsSinceEpoch ?? now,
      'updated_at': now,
    };
    final index = rows.indexWhere((item) => item['id'] == session.id);
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.add(row);
    }
    _writeRows(_roomsKey, rows);
  }

  @override
  Future<List<RoomSession>> listSessions() async {
    final rows = _readRows(_roomsKey)
      ..sort((a, b) =>
          _intValue(b['updated_at']).compareTo(_intValue(a['updated_at'])));
    return rows
        .map((row) => row['payload'])
        .whereType<String>()
        .map(RoomSession.fromPayload)
        .toList();
  }

  @override
  Future<void> saveMessage(String roomId, AgoraMessage message) async {
    final key = _messagesKey(roomId);
    final rows = _readRows(key);
    final row = <String, Object?>{
      'id': message.id,
      'payload': jsonEncode(message.toJson()),
      'created_at': message.createdAt.millisecondsSinceEpoch,
    };
    final index = rows.indexWhere((item) => item['id'] == message.id);
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.add(row);
    }
    rows.sort((a, b) =>
        _intValue(a['created_at']).compareTo(_intValue(b['created_at'])));
    _writeRows(key, rows);
  }

  @override
  Future<List<AgoraMessage>> listMessages(String roomId) async {
    final rows = _readRows(_messagesKey(roomId))
      ..sort((a, b) =>
          _intValue(a['created_at']).compareTo(_intValue(b['created_at'])));
    return rows
        .map((row) => row['payload'])
        .whereType<String>()
        .map((payload) => AgoraMessage.fromJson(
              jsonDecode(payload) as Map<String, dynamic>,
            ))
        .toList();
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    final settings = _readSettings();
    settings[key] = <String, Object?>{
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    html.window.localStorage[_settingsKey] = jsonEncode(settings);
  }

  @override
  Future<String?> readSetting(String key) async {
    final entry = _readSettings()[key];
    if (entry is! Map<String, dynamic>) return null;
    return entry['value'] as String?;
  }

  String _messagesKey(String roomId) => '$_messagePrefix$roomId.v1';

  List<Map<String, dynamic>> _readRows(String key) {
    final raw = html.window.localStorage[key];
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      html.window.localStorage.remove(key);
      return <Map<String, dynamic>>[];
    }
  }

  void _writeRows(String key, List<Map<String, Object?>> rows) {
    html.window.localStorage[key] = jsonEncode(rows);
  }

  Map<String, dynamic> _readSettings() {
    final raw = html.window.localStorage[_settingsKey];
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, dynamic>{};
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      html.window.localStorage.remove(_settingsKey);
      return <String, dynamic>{};
    }
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
