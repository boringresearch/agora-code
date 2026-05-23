import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../storage/local_store.dart';
import '../theme/agora_theme.dart';
import '../widgets/chip.dart';
import '../widgets/soft_card.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({
    super.key,
    required this.store,
    required this.onNewRoom,
    required this.onOpenRoom,
  });

  final LocalStore store;
  final VoidCallback onNewRoom;
  final ValueChanged<RoomSession> onOpenRoom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Meetings',
                        style: displayStyle(
                            fontSize: 30, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: onNewRoom,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New room'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AgoraColors.ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  kIsWeb
                      ? 'Local sessions are persisted in this browser.'
                      : 'Local sessions are persisted on-device with SQLite through sqflite.',
                  style: bodyStyle(fontSize: 14, color: AgoraColors.inkSoft),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<RoomSession>>(
                  future: store.listSessions(),
                  builder: (context, snapshot) {
                    final sessions = snapshot.data ?? const <RoomSession>[];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SoftCard(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (sessions.isEmpty) {
                      return SoftCard(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          children: [
                            const Icon(Icons.meeting_room_outlined,
                                size: 44, color: AgoraColors.mute),
                            const SizedBox(height: 12),
                            Text('No saved rooms yet',
                                style: displayStyle(fontSize: 20)),
                            const SizedBox(height: 8),
                            Text(
                              'Open Think Room once and this page will show your local room history.',
                              textAlign: TextAlign.center,
                              style: bodyStyle(color: AgoraColors.inkSoft),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: onNewRoom,
                              style: FilledButton.styleFrom(
                                backgroundColor: AgoraColors.ink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999)),
                              ),
                              child: const Text('Start a room'),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: sessions.map((session) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: SoftCard(
                            onTap: () => onOpenRoom(session),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AgoraColors.lilac,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: const Color(0xFFE1D8F4)),
                                  ),
                                  child: const Icon(Icons.auto_awesome_outlined,
                                      color: AgoraColors.violet),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(session.topic,
                                          style: displayStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 6),
                                      Text(session.background,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: bodyStyle(
                                              fontSize: 13.5,
                                              color: AgoraColors.inkSoft,
                                              height: 1.4)),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          AgoraChip(
                                              label:
                                                  '${session.participants.length} minds',
                                              icon: Icons.groups_2_outlined),
                                          AgoraChip(
                                              label:
                                                  '${session.agenda.length} agenda',
                                              icon:
                                                  Icons.checklist_rtl_rounded),
                                          AgoraChip(
                                              label: _time(session.updatedAt ??
                                                  session.createdAt),
                                              icon: Icons.schedule_rounded),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AgoraColors.mute),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _time(DateTime? value) {
    if (value == null) return 'local';
    return DateFormat('MMM d').format(value);
  }
}
