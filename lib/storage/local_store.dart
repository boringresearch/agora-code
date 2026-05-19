import '../models/models.dart';

abstract class LocalStore {
  Future<void> init();
  Future<void> saveSession(RoomSession session);
  Future<List<RoomSession>> listSessions();
  Future<void> saveMessage(String roomId, AgoraMessage message);
  Future<List<AgoraMessage>> listMessages(String roomId);
  Future<void> saveSetting(String key, String value);
  Future<String?> readSetting(String key);
}
