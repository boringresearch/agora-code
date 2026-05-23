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

  final void Function(RoomMode mode, RoomSession session) onBegin;

  @override
  State<ThinkRoomScreen> createState() => _ThinkRoomScreenState();
}

class _ThinkRoomScreenState extends State<ThinkRoomScreen> {
  RoomMode _mode = RoomMode.complex;
  RoomSession? _session;
  final _topicController = TextEditingController();
  final _backgroundController = TextEditingController();
  final List<TextEditingController> _agendaTitleControllers = [];
  final List<TextEditingController> _agendaQuestionControllers = [];
  Set<String> _selectedMindIds = {};

  @override
  void initState() {
    super.initState();
    _setDraft(demoRoomFallback);
    _loadDraft();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _backgroundController.dispose();
    _disposeAgendaControllers();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    RoomSession session;
    try {
      session = await RoomDataLoader.loadBundledRoom();
    } catch (error) {
      debugPrint('Failed to load room draft: $error');
      session = demoRoomFallback;
    }
    if (!mounted) return;
    _setDraft(session);
  }

  void _setDraft(RoomSession session) {
    _disposeAgendaControllers();
    _topicController.text = session.topic;
    _backgroundController.text = session.background;
    for (final item in session.agenda) {
      _agendaTitleControllers.add(TextEditingController(text: item.title));
      _agendaQuestionControllers
          .add(TextEditingController(text: item.question));
    }
    final participants =
        session.participants.isEmpty ? suggestedThinkers : session.participants;
    setState(() {
      _session = session.copyWith(participants: participants);
      _selectedMindIds = participants.take(4).map((mind) => mind.id).toSet();
    });
  }

  void _disposeAgendaControllers() {
    for (final controller in _agendaTitleControllers) {
      controller.dispose();
    }
    for (final controller in _agendaQuestionControllers) {
      controller.dispose();
    }
    _agendaTitleControllers.clear();
    _agendaQuestionControllers.clear();
  }

  void _toggleMind(MindProfile mind) {
    setState(() {
      final next = Set<String>.from(_selectedMindIds);
      if (next.contains(mind.id)) {
        if (next.length > 1) next.remove(mind.id);
      } else {
        next.add(mind.id);
      }
      _selectedMindIds = next;
    });
  }

  RoomSession _draftSession() {
    final base = _session ?? demoRoomFallback;
    final agenda = <AgendaItem>[];
    for (var i = 0; i < base.agenda.length; i++) {
      final title = _agendaTitleControllers[i].text.trim();
      final question = _agendaQuestionControllers[i].text.trim();
      if (title.isEmpty && question.isEmpty) continue;
      agenda.add(base.agenda[i].copyWith(
        title: title.isEmpty ? base.agenda[i].title : title,
        question: question.isEmpty ? base.agenda[i].question : question,
      ));
    }
    final selectedParticipants = base.participants
        .where((mind) => _selectedMindIds.contains(mind.id))
        .toList();
    return base.copyWith(
      id: 'room_draft_${DateTime.now().microsecondsSinceEpoch}',
      topic: _topicController.text.trim().isEmpty
          ? base.topic
          : _topicController.text.trim(),
      background: _backgroundController.text.trim().isEmpty
          ? base.background
          : _backgroundController.text.trim(),
      runtimeMode: _mode.label,
      agenda: agenda.isEmpty ? base.agenda : agenda,
      participants: selectedParticipants.isEmpty
          ? base.participants.take(1).toList()
          : selectedParticipants,
      updatedAt: DateTime.now(),
    );
  }

  void _begin() => widget.onBegin(_mode, _draftSession());

  @override
  Widget build(BuildContext context) {
    final session = _session ?? demoRoomFallback;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
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
                          _Header(
                              mode: _mode,
                              onModeChanged: (mode) =>
                                  setState(() => _mode = mode)),
                          const SizedBox(height: 18),
                          _PlannerCard(
                            session: session,
                            mode: _mode,
                            topicController: _topicController,
                            backgroundController: _backgroundController,
                            onBegin: _begin,
                          ),
                          const SizedBox(height: 18),
                          _AgendaPreview(
                            session: session,
                            titleControllers: _agendaTitleControllers,
                            questionControllers: _agendaQuestionControllers,
                          ),
                          if (!showRightRail) ...[
                            const SizedBox(height: 18),
                            _ThinkRoomRightRail(
                              session: session,
                              selectedMindIds: _selectedMindIds,
                              onToggleMind: _toggleMind,
                              onBegin: _begin,
                            ),
                          ],
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
                    child: _ThinkRoomRightRail(
                      session: session,
                      selectedMindIds: _selectedMindIds,
                      onToggleMind: _toggleMind,
                      onBegin: _begin,
                    ),
                  ),
                ),
            ],
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
        Text('Think Room',
            style: displayStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
    required this.topicController,
    required this.backgroundController,
    required this.onBegin,
  });

  final RoomSession session;
  final RoomMode mode;
  final TextEditingController topicController;
  final TextEditingController backgroundController;
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
                child: const Icon(Icons.auto_awesome_outlined,
                    color: AgoraColors.violet),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Draft a council session',
                        style: displayStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'A thinking room pauses the feed, invites different minds, creates agenda, and turns dialogue into public-ready insight cards.',
                      style: bodyStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: AgoraColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _EditableFieldBlock(
            label: 'Question',
            icon: Icons.question_answer_outlined,
            controller: topicController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _EditableFieldBlock(
            label: 'Context',
            icon: Icons.backpack_outlined,
            controller: backgroundController,
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
              AgoraChip(label: session.outcomeType, icon: Icons.map_outlined),
              AgoraChip(
                  label: '${session.agenda.length} editable agenda items',
                  icon: Icons.checklist_rtl_rounded),
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
                  style: bodyStyle(
                      fontSize: 13.5, color: AgoraColors.inkSoft, height: 1.4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableFieldBlock extends StatelessWidget {
  const _EditableFieldBlock(
      {required this.label,
      required this.icon,
      required this.controller,
      required this.maxLines});

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;

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
                Text(label.toUpperCase(),
                    style: bodyStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AgoraColors.mute)),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: maxLines,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: bodyStyle(
                      fontSize: 14.5, height: 1.45, color: AgoraColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaPreview extends StatelessWidget {
  const _AgendaPreview({
    required this.session,
    required this.titleControllers,
    required this.questionControllers,
  });

  final RoomSession session;
  final List<TextEditingController> titleControllers;
  final List<TextEditingController> questionControllers;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Agenda drafted by Room',
                  style:
                      displayStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              const AgoraChip(label: 'editable', icon: Icons.edit_outlined),
            ],
          ),
          const SizedBox(height: 14),
          ...session.agenda.take(4).toList().asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EditableAgendaCard(
                    index: entry.key,
                    active: entry.key == 0,
                    titleController: titleControllers[entry.key],
                    questionController: questionControllers[entry.key],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _EditableAgendaCard extends StatelessWidget {
  const _EditableAgendaCard({
    required this.index,
    required this.active,
    required this.titleController,
    required this.questionController,
  });

  final int index;
  final bool active;
  final TextEditingController titleController;
  final TextEditingController questionController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: active
                ? AgoraColors.accent.withValues(alpha: 0.52)
                : AgoraColors.hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active ? AgoraColors.ink : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: active ? AgoraColors.ink : AgoraColors.hair),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: bodyStyle(
                    fontSize: 12,
                    color: active ? Colors.white : AgoraColors.inkSoft,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: bodyStyle(
                      fontWeight: FontWeight.w800,
                      color: AgoraColors.ink,
                      fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: questionController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: bodyStyle(
                      fontSize: 12.5, color: AgoraColors.inkSoft, height: 1.32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkRoomRightRail extends StatelessWidget {
  const _ThinkRoomRightRail({
    required this.session,
    required this.selectedMindIds,
    required this.onToggleMind,
    required this.onBegin,
  });

  final RoomSession session;
  final Set<String> selectedMindIds;
  final ValueChanged<MindProfile> onToggleMind;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final participants =
        session.participants.isEmpty ? suggestedThinkers : session.participants;
    return Column(
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested thinkers',
                  style:
                      displayStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Invite minds that disagree productively. The host will manage rhythm, turn-taking, and summaries.',
                style: bodyStyle(
                    fontSize: 12.8, color: AgoraColors.inkSoft, height: 1.38),
              ),
              const SizedBox(height: 14),
              ...participants.take(5).map(
                    (mind) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SelectableThinker(
                        mind: mind,
                        selected: selectedMindIds.contains(mind.id),
                        onTap: () => onToggleMind(mind),
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
              Text('Two engines, one UI',
                  style: displayStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Switch between turn-by-turn orchestration and full prompt simulation. Both render as the same live room.',
                style: bodyStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.74),
                    height: 1.45),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onBegin,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start now'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AgoraColors.ink,
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

class _SelectableThinker extends StatelessWidget {
  const _SelectableThinker(
      {required this.mind, required this.selected, required this.onTap});

  final MindProfile mind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AgoraColors.canvas : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ThinkerAvatar(name: mind.name, size: 42, color: mind.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mind.name,
                        style: bodyStyle(
                            fontWeight: FontWeight.w800,
                            color: AgoraColors.ink)),
                    Text(
                      mind.role,
                      style: bodyStyle(
                          fontSize: 12,
                          color: AgoraColors.mute,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AgoraColors.green : AgoraColors.mute,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
