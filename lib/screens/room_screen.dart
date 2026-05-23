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
    this.initialSession,
    required this.store,
    required this.chatClient,
    required this.onBackToPlanner,
  });

  final RoomMode initialMode;
  final RoomSession? initialSession;
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
    final session =
        widget.initialSession ?? await RoomDataLoader.loadBundledRoom();
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
        if (_messages.isNotEmpty && _messages.length % 5 == 0) {
          setState(() {
            final maxIndex =
                session.agenda.isEmpty ? 0 : session.agenda.length - 1;
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
          final showRightRail = constraints.maxWidth >= 960;
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _RoomTopBar(
                          session: session,
                          mode: _mode,
                          onModeChanged: (mode) => setState(() => _mode = mode),
                          onBack: widget.onBackToPlanner,
                          compact: !showRightRail,
                        ),
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth < 700 ? 16 : 26,
                              12,
                              constraints.maxWidth < 700 ? 16 : 26,
                              constraints.maxWidth < 820 ? 230 : 170,
                            ),
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ChatBubble(
                                message: message,
                                avatarColor:
                                    _colorFor(session, message.speakerId),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 18),
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
                        child: _DetailsPanel(
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
                left: 0,
                right: showRightRail ? 300 : 0,
                bottom: 0,
                child: _ComposerBar(
                  session: session,
                  agendaIndex: _agendaIndex,
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
                  style: bodyStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AgoraColors.mute)
                      .copyWith(letterSpacing: 2.2),
                ),
                const SizedBox(height: 4),
                Text(
                  session.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: displayStyle(
                      fontSize: compact ? 15 : 17, fontWeight: FontWeight.w800),
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


class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
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
    final participants =
        session.participants.isEmpty ? suggestedThinkers : session.participants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: displayStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        Text(
          'Participants',
          style: bodyStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AgoraColors.mute,
          ).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        ...participants.take(6).map(
              (mind) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    ThinkerAvatar(
                        name: mind.name, size: 40, color: mind.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mind.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle(
                                fontWeight: FontWeight.w800,
                                color: AgoraColors.ink),
                          ),
                          Text(
                            mind.description.isNotEmpty
                                ? '${mind.role} · ${mind.description}'
                                : mind.role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle(
                                fontSize: 11.5, color: AgoraColors.mute),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              ThinkerAvatar(
                  name: 'You', size: 40, color: AgoraColors.ink, dark: true, showInitial: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You',
                        style: bodyStyle(
                            fontWeight: FontWeight.w800,
                            color: AgoraColors.ink)),
                    Text('Builder',
                        style: bodyStyle(
                            fontSize: 11.5, color: AgoraColors.mute)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: AgoraColors.hair),
        const SizedBox(height: 16),
        const MemorySummaryCard(),
        const SizedBox(height: 16),
        SoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ENGINE',
                style: bodyStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AgoraColors.mute,
                ).copyWith(letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              AgoraChip(
                label: mode.label,
                icon: mode == RoomMode.complex
                    ? Icons.account_tree_outlined
                    : Icons.short_text_rounded,
                backgroundColor: mode == RoomMode.complex
                    ? AgoraColors.sky
                    : AgoraColors.lilac,
                foregroundColor: mode == RoomMode.complex
                    ? const Color(0xFF264FB1)
                    : AgoraColors.violet,
                borderColor: mode == RoomMode.complex
                    ? const Color(0xFFCCDDF3)
                    : const Color(0xFFE1D8F4),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(mode == RoomMode.complex
                    ? 'Run next turn'
                    : 'Simulate room'),
                style: FilledButton.styleFrom(
                  backgroundColor: AgoraColors.ink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AgoraColors.hair,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.session,
    required this.agendaIndex,
    required this.controller,
    required this.running,
    required this.mode,
    required this.error,
    required this.onSend,
    required this.onRun,
  });

  final RoomSession session;
  final int agendaIndex;
  final TextEditingController controller;
  final bool running;
  final RoomMode mode;
  final String? error;
  final VoidCallback onSend;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
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
              child: Text(error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      bodyStyle(fontSize: 12, color: const Color(0xFFB23A66))),
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
                    prefixIcon: Icon(Icons.keyboard_rounded,
                        size: 18, color: AgoraColors.mute),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onSend,
                style: IconButton.styleFrom(
                    backgroundColor: AgoraColors.ink,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(mode == RoomMode.complex
                        ? Icons.skip_next_rounded
                        : Icons.auto_awesome_rounded),
                label: Text(mode == RoomMode.complex ? 'Next' : 'Simulate'),
                style: FilledButton.styleFrom(
                  backgroundColor: AgoraColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AgoraColors.hair,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ],
          ),
          if (session.agenda.isNotEmpty) ...[  
            const SizedBox(height: 10),
            _AgendaProgressBar(
                session: session, agendaIndex: agendaIndex),
          ],
        ],
      ),
    );
  }
}

class _AgendaProgressBar extends StatelessWidget {
  const _AgendaProgressBar({
    required this.session,
    required this.agendaIndex,
  });

  final RoomSession session;
  final int agendaIndex;

  @override
  Widget build(BuildContext context) {
    final items = session.agenda;
    final count = items.length;
    if (count == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < count; i++) ...[  
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i <= agendaIndex
                                ? AgoraColors.ink
                                : AgoraColors.hair,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: i <= agendaIndex
                                ? AgoraColors.ink
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i <= agendaIndex
                                  ? AgoraColors.ink
                                  : AgoraColors.hair,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: bodyStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: i <= agendaIndex
                                    ? Colors.white
                                    : AgoraColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            items[i].title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle(
                              fontSize: 11,
                              fontWeight: i == agendaIndex
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: i == agendaIndex
                                  ? AgoraColors.ink
                                  : AgoraColors.inkSoft,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
