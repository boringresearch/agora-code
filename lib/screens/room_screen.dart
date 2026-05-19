import 'package:flutter/material.dart';

import '../data/room_data_loader.dart';
import '../data/sample_data.dart';
import '../llm/llm_client.dart';
import '../models/models.dart';
import '../room/room_orchestrator.dart';
import '../storage/local_store.dart';
import '../theme/agora_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/chip.dart';
import '../widgets/room_widgets.dart';
import '../widgets/soft_card.dart';

class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({
    super.key,
    required this.initialMode,
    required this.store,
    required this.chatClient,
    required this.onBackToPlanner,
  });

  final RoomMode initialMode;
  final LocalStore store;
  final ChatClient chatClient;
  final VoidCallback onBackToPlanner;

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  late RoomMode _mode;
  late RoomOrchestrator _orchestrator;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  RoomSession? _session;
  List<AgoraMessage> _messages = const [];
  int _agendaIndex = 0;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _orchestrator = RoomOrchestrator(widget.chatClient);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await RoomDataLoader.loadBundledRoom();
    final messages = seedRoomMessages(session);
    if (!mounted) return;
    setState(() {
      _session = session;
      _messages = messages;
    });
    await widget.store.saveSession(session);
    for (final message in messages) {
      await widget.store.saveMessage(session.id, message);
    }
    _jumpToBottom();
  }

  Future<void> _runModel() async {
    final session = _session;
    if (session == null || _running) return;
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      if (_mode == RoomMode.complex) {
        final next = await _orchestrator.runNextComplexTurn(
          session: session,
          transcript: _messages,
          agendaIndex: _agendaIndex,
        );
        await _append(next);
        if (_messages.length > 0 && _messages.length % 5 == 0) {
          setState(() {
            final maxIndex = session.agenda.isEmpty ? 0 : session.agenda.length - 1;
            _agendaIndex = (_agendaIndex + 1).clamp(0, maxIndex).toInt();
          });
        }
      } else {
        final dialogue = await _orchestrator.runSinglePromptSimulation(
          session: session,
          transcript: _messages,
        );
        for (final message in dialogue) {
          await _append(message, jump: false);
        }
        _jumpToBottom();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _sendUserMessage() async {
    final session = _session;
    final text = _controller.text.trim();
    if (session == null || text.isEmpty) return;
    _controller.clear();
    await _append(AgoraMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      speakerId: 'you',
      speakerName: 'You',
      role: 'Builder',
      text: text,
      kind: MessageKind.user,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> _append(AgoraMessage message, {bool jump = true}) async {
    final session = _session;
    if (session == null) return;
    setState(() => _messages = [..._messages, message]);
    await widget.store.saveMessage(session.id, message);
    if (jump) _jumpToBottom();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session ?? demoRoomFallback;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLeftRail = constraints.maxWidth >= 900;
          final showRightRail = constraints.maxWidth >= 1120;
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLeftRail)
                    SizedBox(
                      width: 288,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(26, 22, 12, 110),
                        child: _LeftRail(session: session, agendaIndex: _agendaIndex),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _RoomTopBar(
                          session: session,
                          mode: _mode,
                          onModeChanged: (mode) => setState(() => _mode = mode),
                          onBack: widget.onBackToPlanner,
                          compact: !showLeftRail,
                        ),
                        if (!showLeftRail)
                          _MobileAgendaStrip(session: session, agendaIndex: _agendaIndex),
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth < 700 ? 16 : 26,
                              12,
                              constraints.maxWidth < 700 ? 16 : 26,
                              constraints.maxWidth < 820 ? 210 : 150,
                            ),
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ChatBubble(
                                message: message,
                                avatarColor: _colorFor(session, message.speakerId),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemCount: _messages.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showRightRail)
                    SizedBox(
                      width: 300,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(10, 22, 20, 110),
                        child: _RightRail(
                          session: session,
                          messages: _messages,
                          mode: _mode,
                          running: _running,
                          onRun: _runModel,
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                left: showLeftRail ? 288 : 0,
                right: showRightRail ? 300 : 0,
                bottom: 0,
                child: _ComposerBar(
                  controller: _controller,
                  running: _running,
                  mode: _mode,
                  error: _error,
                  onSend: _sendUserMessage,
                  onRun: _runModel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _colorFor(RoomSession session, String speakerId) {
    if (speakerId == 'you') return AgoraColors.ink;
    final matches = session.participants.where((mind) => mind.id == speakerId);
    if (matches.isEmpty) return AgoraColors.accent;
    return matches.first.color;
  }
}

class _RoomTopBar extends StatelessWidget {
  const _RoomTopBar({
    required this.session,
    required this.mode,
    required this.onModeChanged,
    required this.onBack,
    required this.compact,
  });

  final RoomSession session;
  final RoomMode mode;
  final ValueChanged<RoomMode> onModeChanged;
  final VoidCallback onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 26, 18, compact ? 16 : 26, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AgoraColors.inkSoft,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'THINKING ROOM · LISBON · LIVE',
                  style: bodyStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AgoraColors.mute).copyWith(letterSpacing: 2.2),
                ),
                const SizedBox(height: 4),
                Text(
                  session.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: displayStyle(fontSize: compact ? 15 : 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (!compact) ModeSelector(value: mode, onChanged: onModeChanged),
          const SizedBox(width: 8),
          const SoftIconButton(icon: Icons.more_horiz_rounded),
        ],
      ),
    );
  }
}

class _LeftRail extends StatelessWidget {
  const _LeftRail({required this.session, required this.agendaIndex});

  final RoomSession session;
  final int agendaIndex;

  @override
  Widget build(BuildContext context) {
    final participants = session.participants.isEmpty ? suggestedThinkers : session.participants;
    return Column(
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INVITED COUNCIL', style: _railTitle()),
              const SizedBox(height: 14),
              ...participants.take(5).map(
                (mind) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ThinkerAvatar(name: mind.name, size: 38, color: mind.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mind.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyStyle(fontWeight: FontWeight.w800, color: AgoraColors.ink)),
                            Text(mind.role, style: bodyStyle(fontSize: 11.5, color: AgoraColors.mute)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SESSION JOURNEY', style: _railTitle()),
              const SizedBox(height: 14),
              ...session.agenda.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AgendaCard(item: entry.value, index: entry.key, active: entry.key == agendaIndex),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _railTitle() => bodyStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AgoraColors.mute).copyWith(letterSpacing: 1.3);
}

class _RightRail extends StatelessWidget {
  const _RightRail({
    required this.session,
    required this.messages,
    required this.mode,
    required this.running,
    required this.onRun,
  });

  final RoomSession session;
  final List<AgoraMessage> messages;
  final RoomMode mode;
  final bool running;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final current = messages.isEmpty ? null : messages.last;
    final challenge = (0.18 + messages.where((m) => !m.isUser).length * 0.055).clamp(0.18, 0.86);
    return Column(
      children: [
        RoomMetricCard(
          title: 'Speaking now',
          child: Row(
            children: [
              ThinkerAvatar(
                name: current?.speakerName ?? 'Room',
                size: 44,
                color: _currentColor(session, current),
                dark: current?.isUser == true,
                showInitial: current?.isUser == true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current?.speakerName ?? 'Room',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(fontWeight: FontWeight.w800, color: AgoraColors.ink),
                    ),
                    Text(
                      running ? 'thinking...' : (current?.role ?? 'listening...'),
                      style: bodyStyle(fontSize: 12, color: AgoraColors.accent, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RoomMetricCard(
          title: 'Round',
          child: Row(
            children: [
              Text('${(messages.length / 2).ceil()}', style: displayStyle(fontSize: 34, fontWeight: FontWeight.w800)),
              Text(' / 8', style: bodyStyle(fontSize: 15, color: AgoraColors.mute, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RoomMetricCard(
          title: 'Challenge score',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressPill(value: challenge.toDouble()),
              const SizedBox(height: 8),
              Text('Higher = more disagreement', style: bodyStyle(fontSize: 12, color: AgoraColors.inkSoft)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Engine', style: displayStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              AgoraChip(
                label: mode.label,
                icon: mode == RoomMode.complex ? Icons.account_tree_outlined : Icons.short_text_rounded,
                backgroundColor: mode == RoomMode.complex ? AgoraColors.sky : AgoraColors.lilac,
                foregroundColor: mode == RoomMode.complex ? const Color(0xFF264FB1) : AgoraColors.violet,
                borderColor: mode == RoomMode.complex ? const Color(0xFFCCDDF3) : const Color(0xFFE1D8F4),
              ),
              const SizedBox(height: 12),
              Text(
                mode == RoomMode.complex
                    ? 'Host chooses next speaker and sends one model call per turn.'
                    : 'One model call drafts the whole room, then UI renders every turn.',
                style: bodyStyle(fontSize: 12.5, color: AgoraColors.inkSoft, height: 1.42),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(mode == RoomMode.complex ? 'Run next turn' : 'Simulate room'),
                style: FilledButton.styleFrom(
                  backgroundColor: AgoraColors.ink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AgoraColors.hair,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const MemorySummaryCard(),
      ],
    );
  }

  Color _currentColor(RoomSession session, AgoraMessage? current) {
    if (current == null) return AgoraColors.accent;
    if (current.isUser) return AgoraColors.ink;
    final matches = session.participants.where((mind) => mind.id == current.speakerId);
    if (matches.isEmpty) return AgoraColors.accent;
    return matches.first.color;
  }
}

class _MobileAgendaStrip extends StatelessWidget {
  const _MobileAgendaStrip({required this.session, required this.agendaIndex});

  final RoomSession session;
  final int agendaIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = session.agenda[index];
          final active = index == agendaIndex;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withOpacity(0.68),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? AgoraColors.accent.withOpacity(0.5) : AgoraColors.hair),
            ),
            child: Row(
              children: [
                Text('${index + 1}', style: bodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? AgoraColors.accent : AgoraColors.mute)),
                const SizedBox(width: 6),
                Text(item.title, style: bodyStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AgoraColors.ink)),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: session.agenda.length,
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.running,
    required this.mode,
    required this.error,
    required this.onSend,
    required this.onRun,
  });

  final TextEditingController controller;
  final bool running;
  final RoomMode mode;
  final String? error;
  final VoidCallback onSend;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: const Border(top: BorderSide(color: AgoraColors.hair)),
        boxShadow: [
          BoxShadow(
            color: AgoraColors.ink.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(error!, maxLines: 2, overflow: TextOverflow.ellipsis, style: bodyStyle(fontSize: 12, color: const Color(0xFFB23A66))),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ask the room or add context...',
                    prefixIcon: Icon(Icons.keyboard_rounded, size: 18, color: AgoraColors.mute),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onSend,
                style: IconButton.styleFrom(backgroundColor: AgoraColors.ink, foregroundColor: Colors.white),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(mode == RoomMode.complex ? Icons.skip_next_rounded : Icons.auto_awesome_rounded),
                label: Text(mode == RoomMode.complex ? 'Next' : 'Simulate'),
                style: FilledButton.styleFrom(
                  backgroundColor: AgoraColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AgoraColors.hair,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
