import 'package:flutter/material.dart';

import '../data/room_data_loader.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import '../storage/local_store.dart';
import '../theme/agora_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/chip.dart';
import '../widgets/room_widgets.dart';
import '../widgets/soft_card.dart';

class ThinkRoomScreen extends StatefulWidget {
  const ThinkRoomScreen({super.key, required this.store, required this.onBegin});

  final LocalStore store;
  final void Function(RoomMode mode, RoomSession session) onBegin;

  @override
  State<ThinkRoomScreen> createState() => _ThinkRoomScreenState();
}

class _ThinkRoomScreenState extends State<ThinkRoomScreen> {
  RoomMode _mode = RoomMode.complex;
  RoomSession? _session;
  final _topicController = TextEditingController();
  final _backgroundController = TextEditingController();
  Set<String> _selectedMindIds = {};
  List<MindProfile> _allThinkers = const [];
  bool _thinkersLoading = true;

  @override
  void initState() {
    super.initState();
    _setDraft(demoRoomFallback);
    _loadDraft();
    _loadThinkers();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loadThinkers() async {
    final customRaw = await widget.store.readSetting(kCustomThinkersKey);
    final deletedRaw = await widget.store.readSetting(kDeletedThinkersKey);
    if (!mounted) return;
    final customThinkers = decodeThinkersSetting(customRaw);
    final deletedIds = decodeStringSet(deletedRaw);
    setState(() {
      _allThinkers = buildAllThinkers(
          customThinkers: customThinkers, deletedIds: deletedIds);
      _thinkersLoading = false;
    });
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
    _topicController.text = session.topic;
    _backgroundController.text = session.background;
    setState(() {
      _session = session;
      _selectedMindIds = {};
    });
  }

  void _toggleMind(MindProfile mind) {
    setState(() {
      final next = Set<String>.from(_selectedMindIds);
      if (next.contains(mind.id)) {
        next.remove(mind.id);
      } else {
        next.add(mind.id);
      }
      _selectedMindIds = next;
    });
  }

  /// Build the frozen participant list for the new room session.
  /// Priority: live store profile (full persona) > session snapshot fallback.
  /// This makes each room self-contained — future edits/deletions in the
  /// Thinkers tab don't affect rooms that have already started.
  List<MindProfile> _resolveParticipants() {
    final liveById = {for (final t in _allThinkers) t.id: t};
    return _selectedMindIds
        .map((id) => liveById[id])
        .whereType<MindProfile>()
        .toList();
  }

  RoomSession _draftSession() {
    final base = _session ?? demoRoomFallback;
    return base.copyWith(
      id: 'room_draft_${DateTime.now().microsecondsSinceEpoch}',
      topic: _topicController.text.trim().isEmpty
          ? base.topic
          : _topicController.text.trim(),
      background: _backgroundController.text.trim().isEmpty
          ? base.background
          : _backgroundController.text.trim(),
      runtimeMode: _mode.label,
      agenda: const [],
      participants: _resolveParticipants(),
      updatedAt: DateTime.now(),
    );
  }

  void _begin() {
    if (_selectedMindIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one thinker to begin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onBegin(_mode, _draftSession());
  }

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
                            mode: _mode,
                            topicController: _topicController,
                            backgroundController: _backgroundController,
                            onBegin: _begin,
                          ),
                          if (!showRightRail) ...[
                            const SizedBox(height: 18),
                            _ThinkRoomRightRail(
                              allThinkers: _allThinkers,
                              loading: _thinkersLoading,
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
                  child: _ThinkRoomRightRail(
                    allThinkers: _allThinkers,
                    loading: _thinkersLoading,
                    selectedMindIds: _selectedMindIds,
                    onToggleMind: _toggleMind,
                    onBegin: _begin,
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
    required this.mode,
    required this.topicController,
    required this.backgroundController,
    required this.onBegin,
  });

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
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
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

class _ThinkRoomRightRail extends StatefulWidget {
  const _ThinkRoomRightRail({
    required this.allThinkers,
    required this.loading,
    required this.selectedMindIds,
    required this.onToggleMind,
    required this.onBegin,
  });

  final List<MindProfile> allThinkers;
  final bool loading;
  final Set<String> selectedMindIds;
  final ValueChanged<MindProfile> onToggleMind;
  final VoidCallback onBegin;

  @override
  State<_ThinkRoomRightRail> createState() => _ThinkRoomRightRailState();
}

class _ThinkRoomRightRailState extends State<_ThinkRoomRightRail> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.trim()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MindProfile> get _filtered {
    final thinkers =
        widget.allThinkers.isEmpty ? suggestedThinkers : widget.allThinkers;
    if (_query.isEmpty) return thinkers;
    final q = _query.toLowerCase();
    return thinkers
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.role.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedCount = widget.selectedMindIds.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 22, 20, 110),
      child: Column(
        children: [
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Thinkers',
                          style: displayStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    if (selectedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AgoraColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$selectedCount selected',
                          style: bodyStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Invite minds that disagree productively.',
                  style: bodyStyle(
                      fontSize: 12.5,
                      color: AgoraColors.inkSoft,
                      height: 1.35),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search thinkers...',
                    hintStyle:
                        bodyStyle(fontSize: 13, color: AgoraColors.mute),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AgoraColors.mute),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: _searchController.clear,
                            color: AgoraColors.mute,
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                    filled: true,
                    fillColor: AgoraColors.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AgoraColors.hair, width: 1.5),
                    ),
                  ),
                  style: bodyStyle(fontSize: 13, color: AgoraColors.ink),
                ),
                const SizedBox(height: 10),
                if (widget.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No thinkers found.',
                        style:
                            bodyStyle(fontSize: 13, color: AgoraColors.mute)),
                  )
                else
                  ...filtered.map(
                    (mind) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SelectableThinker(
                        mind: mind,
                        selected: widget.selectedMindIds.contains(mind.id),
                        onTap: () => widget.onToggleMind(mind),
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
                  onPressed: widget.onBegin,
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
      ),
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
      color: selected
          ? AgoraColors.ink.withValues(alpha: 0.05)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ThinkerAvatar(name: mind.name, size: 40, color: mind.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mind.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle(
                            fontWeight: FontWeight.w800,
                            color: AgoraColors.ink)),
                    Text(
                      mind.description.isNotEmpty
                          ? '${mind.role} · ${mind.description}'
                          : mind.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(
                          fontSize: 11.5,
                          color: AgoraColors.mute,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AgoraColors.green : AgoraColors.hair,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
