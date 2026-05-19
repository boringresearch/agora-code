import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';
import 'sample_data.dart';

class RoomDataLoader {
  static Future<RoomSession> loadBundledRoom() async {
    try {
      final raw = await rootBundle.loadString('assets/data/room_data.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RoomSession.fromRoomDataJson(json);
    } catch (_) {
      return demoRoomFallback;
    }
  }
}
