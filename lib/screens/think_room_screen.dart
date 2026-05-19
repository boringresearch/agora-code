import 'package:flutter/material.dart';

import '../data/room_data_loader.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import '../theme/agora_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/chip.dart';
import '../widgets/room_widgets.dart';
import '../widgets/soft_card.dart';

class ThinkRoomScreen extends StatefulWidget {
  const ThinkRoomScreen({super.key, required this.onBegin});

  final ValueChanged<RoomMode> onBegin;

  @override
  State<ThinkRoomScreen> createState() => _ThinkRoomScreenState();
}

class _ThinkRoomScreenState extends State<ThinkRoomScreen> {
  RoomMode _mode = RoomMode.complex;
  late Future<RoomSession> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = RoomDataLoader.loadBundledRoom();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<RoomSession>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          final session = snapshot.data ?? demoRoomFallback;
          return LayoutBuilder(
            builder: (context, constraints) {
              final showRightRail = constraints.maxWidth >= 1050;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth < 820 ? 16 : 32,
                        22,
                        showRightRail ? 22 : 32,
                        110,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 880),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(mode: _mode, onModeChanged: (mode) => setState(() => _mode = mode)),
                              const SizedBox(height: 18),
                              _PlannerCard(session: session, mode: _mode, onBegin: () => widget.onBegin(_mode)),
                              const SizedBox(height: 18),
                              _AgendaPreview(session: session),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showRightRail)
                    SizedBox(
                      width: 318,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(0, 22, 20, 110),
                        child: _ThinkRoomRightRail(session: session, onBegin: () => widget.onBegin(_mode)),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mode, required this.onModeChanged});

  final RoomMode mode;
  final ValueChanged<RoomMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('|', style: bodyStyle(fontSize: 18, color: AgoraColors.mute)),
        const SizedBox(width: 12),
        Text('Think Room', style: displayStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const Spacer(),
        ModeSelector(value: mode, onChanged: onModeChanged),
        const SizedBox(width: 10),
        const SoftIconButton(icon: Icons.help_outline_rounded),
        const SizedBox(width: 8),
        const SoftIconButton(icon: Icons.auto_awesome_outlined),
      ],
    );
  }
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({
    required this.session,
    required this.mode,
    required this.onBegin,
  });

  final RoomSession session;
  final RoomMode mode;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AgoraColors.lilac,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE1D8F4)),
                ),
                child: const Icon(Icons.auto_awesome_outlined, color: AgoraColors.violet),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Draft a council session', style: displayStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'A thinking room pauses the feed, invites different minds, creates agenda, and turns dialogue into public-ready insight cards.',
                      style: bodyStyle(fontSize: 14.5, height: 1.5, color: AgoraColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _FieldBlock(
            label: 'Question',
            icon: Icons.question_answer_outlined,
            text: session.topic,
          ),
          const SizedBox(height: 14),
          _FieldBlock(
            label: 'Context',
            icon: Icons.backpack_outlined,
            text: session.background,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AgoraChip(
                label: mode.label,
                icon: mode == RoomMode.complex ? Icons.account_tree_outlined : Icons.short_text_rounded,
                backgroundColor: mode == RoomMode.complex ? AgoraColors.sky : AgoraColors.lilac,
                foregroundColor: mode == RoomMode.complex ? const Color(0xFF264FB1) : AgoraColors.violet,
                borderColor: mode == RoomMode.complex ? const Color(0xFFCCDDF3) : const Color(0xFFE1D8F4),
              ),
              AgoraChip(label: session.outcomeType, icon: Icons.map_outlined),
              AgoraChip(label: session.runtimeMode, icon: Icons.tune_rounded),
              AgoraChip(label: '${session.agenda.length} agenda items', icon: Icons.checklist_rtl_rounded),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  mode == RoomMode.complex
                      ? 'Complex mode: host selects the next mind, tracks agenda, and calls the model each turn.'
                      : 'Prompt mode: one structured prompt generates a complete multi-person dialogue, then the same chat UI renders it.',
                  style: bodyStyle(fontSize: 13.5, color: AgoraColors.inkSoft, height: 1.4),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: onBegin,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Begin dialogue'),
                style: FilledButton.styleFrom(
                  backgroundColor: AgoraColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.icon, required this.text});

  final String label;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgoraColors.hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AgoraColors.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: bodyStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AgoraColors.mute)),
                const SizedBox(height: 6),
                Text(text, style: bodyStyle(fontSize: 14.5, height: 1.45, color: AgoraColors.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaPreview extends StatelessWidget {
  const _AgendaPreview({required this.session});

  final RoomSession session;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Agenda drafted by Room', style: displayStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              const AgoraChip(label: 'editable', icon: Icons.edit_outlined),
            ],
          ),
          const SizedBox(height: 14),
          ...session.agenda.take(4).toList().asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AgendaCard(item: entry.value, index: entry.key, active: entry.key == 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkRoomRightRail extends StatelessWidget {
  const _ThinkRoomRightRail({required this.session, required this.onBegin});

  final RoomSession session;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final participants = session.participants.isEmpty ? suggestedThinkers : session.participants;
    return Column(
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested thinkers', style: displayStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Invite minds that disagree productively. The host will manage rhythm, turn-taking, and summaries.',
                style: bodyStyle(fontSize: 12.8, color: AgoraColors.inkSoft, height: 1.38),
              ),
              const SizedBox(height: 14),
              ...participants.take(5).map(
                (mind) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      ThinkerAvatar(name: mind.name, size: 46, color: mind.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mind.name, style: bodyStyle(fontWeight: FontWeight.w800, color: AgoraColors.ink)),
                            Text(
                              mind.role,
                              style: bodyStyle(fontSize: 12, color: AgoraColors.mute, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AgoraColors.green, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SoftCard(
          backgroundColor: AgoraColors.ink,
          borderColor: AgoraColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Two engines, one UI', style: displayStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Switch between turn-by-turn orchestration and full prompt simulation. Both render as the same live room.',
                style: bodyStyle(fontSize: 13, color: Colors.white.withOpacity(0.74), height: 1.45),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onBegin,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start now'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AgoraColors.ink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
