import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../llm/llm_client.dart';
import '../models/models.dart';
import '../storage/file_thinker_store.dart';
import '../storage/local_store.dart';
import '../theme/agora_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/chip.dart';
import '../widgets/markdown_text.dart';
import '../widgets/soft_card.dart';

class ThinkersScreen extends StatefulWidget {
  const ThinkersScreen({
    super.key,
    required this.store,
    required this.onStartConversation,
  });

  final LocalStore store;
  final ValueChanged<MindProfile> onStartConversation;

  @override
  State<ThinkersScreen> createState() => _ThinkersScreenState();
}

class _ThinkersScreenState extends State<ThinkersScreen> {
  final _searchController = TextEditingController();
  final _fileStore = FileThinkerStore();
  List<MindProfile> _customThinkers = const [];
  Set<String> _deletedThinkerIds = const {};
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _initAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    await _fileStore.init();
    await _loadCustomThinkers();
  }

  Future<void> _loadCustomThinkers() async {
    final thinkers = await _fileStore.listThinkers();
    final deletedIds = await _fileStore.getDeletedIds();
    if (!mounted) return;
    setState(() {
      _customThinkers = thinkers;
      _deletedThinkerIds = deletedIds;
      _loading = false;
    });
  }

  Future<void> _addThinker(MindProfile thinker) async {
    await _fileStore.saveThinker(thinker);
    await _fileStore.clearDeletedIds();
    await _loadCustomThinkers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${thinker.name} added.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _importThinkers(List<MindProfile> thinkers) async {
    for (final thinker in thinkers) {
      await _fileStore.saveThinker(thinker);
    }
    await _fileStore.clearDeletedIds();
    await _loadCustomThinkers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${thinkers.length} thinker${thinkers.length == 1 ? '' : 's'} imported.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _deleteThinker(MindProfile thinker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${thinker.name}?'),
        content: const Text(
          'This removes the thinker from the Thinkers tab and deletes their file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AgoraColors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _fileStore.deleteThinker(thinker.id);
    await _deleteThinkerLocalData(widget.store, thinker);
    await _loadCustomThinkers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${thinker.name} deleted.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _clearDeletedThinkers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore all deleted thinkers?'),
        content: Text(
          'This will restore ${_deletedThinkerIds.length} deleted thinker(s) to the list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AgoraColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _fileStore.clearDeletedIds();
    await _loadCustomThinkers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All deleted thinkers restored.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  void _openAddDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddThinkerDialog(onSave: _addThinker),
    );
  }

  void _openImportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _ImportThinkersDialog(onImport: _importThinkers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allThinkers = _oneToOneThinkers(
      customThinkers: _customThinkers,
      deletedThinkerIds: _deletedThinkerIds,
    );
    final thinkers = _filterThinkersByName(allThinkers, _searchQuery);
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Thinkers',
                        style: displayStyle(
                            fontSize: 30, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _openImportDialog,
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Import'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _openAddDialog,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add thinker'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AgoraColors.ink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_deletedThinkerIds.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _clearDeletedThinkers,
                        icon: const Icon(Icons.restore_from_trash_outlined),
                        tooltip: 'Restore ${_deletedThinkerIds.length} deleted',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a mind, then start a focused one-to-one meeting.',
                  style: bodyStyle(fontSize: 14, color: AgoraColors.inkSoft),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search thinkers by name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Clear search',
                          ),
                  ),
                  style: bodyStyle(fontSize: 14, color: AgoraColors.ink),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const SoftCard(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (thinkers.isEmpty)
                  SoftCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'No thinkers found.',
                          style: bodyStyle(color: AgoraColors.inkSoft),
                        ),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 620
                              ? 2
                              : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: columns == 1 ? 3.6 : 1.28,
                        ),
                        itemCount: thinkers.length,
                        itemBuilder: (context, index) {
                          final thinker = thinkers[index];
                          return _ThinkerProfileCard(
                            thinker: thinker,
                            onTap: () => widget.onStartConversation(thinker),
                            onDelete: () => _deleteThinker(thinker),
                          );
                        },
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
}

class _AddThinkerDialog extends StatefulWidget {
  const _AddThinkerDialog({required this.onSave});

  final ValueChanged<MindProfile> onSave;

  @override
  State<_AddThinkerDialog> createState() => _AddThinkerDialogState();
}

class _AddThinkerDialogState extends State<_AddThinkerDialog> {
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  Color _color = AgoraColors.accent;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final prompt = _promptController.text.trim();
    if (name.isEmpty || prompt.isEmpty) {
      setState(() => _error = 'Name and prompt are required.');
      return;
    }
    final thinker = MindProfile(
      id: _idFromName(name),
      name: name,
      handle: '@${_idFromName(name)}',
      role: 'Custom thinker',
      description: _descriptionFromPrompt(prompt),
      persona: prompt,
      color: _color,
    );
    widget.onSave(thinker);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Add thinker',
                      style: displayStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DialogField(label: 'Name', controller: _nameController),
              const SizedBox(height: 12),
              _DialogField(
                label: 'Final system prompt',
                controller: _promptController,
                maxLines: 10,
                hintText:
                    'This exact prompt will be sent as the system prompt for this thinker.',
              ),
              const SizedBox(height: 14),
              Text('COLOR',
                  style: bodyStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AgoraColors.mute)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _thinkerPalette
                    .map(
                      (color) => _ColorDot(
                        color: color,
                        selected: color == _color,
                        onTap: () => setState(() => _color = color),
                      ),
                    )
                    .toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: bodyStyle(color: AgoraColors.pink)),
              ],
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save thinker'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AgoraColors.ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportThinkersDialog extends StatefulWidget {
  const _ImportThinkersDialog({required this.onImport});

  final ValueChanged<List<MindProfile>> onImport;

  @override
  State<_ImportThinkersDialog> createState() => _ImportThinkersDialogState();
}

class _ImportThinkersDialogState extends State<_ImportThinkersDialog> {
  final _controller = TextEditingController(text: _importExample);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _import() {
    try {
      final thinkers = _parseImportedThinkers(_controller.text);
      if (thinkers.isEmpty) {
        setState(() => _error = 'No thinkers found in JSON.');
        return;
      }
      widget.onImport(thinkers);
      Navigator.of(context).pop();
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Import thinkers',
                      style: displayStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Paste a JSON object or array. Supported fields: id, name, prompt/persona/systemPrompt, color.',
                style: bodyStyle(fontSize: 13, color: AgoraColors.inkSoft),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  style: bodyStyle(fontSize: 13, height: 1.45),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: bodyStyle(color: AgoraColors.pink)),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AgoraColors.ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: bodyStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AgoraColors.mute)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(hintText: hintText),
          style: bodyStyle(fontSize: 14, color: AgoraColors.ink),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AgoraColors.ink : Colors.white,
            width: selected ? 3 : 2,
          ),
          boxShadow: AgoraShadows.card,
        ),
      ),
    );
  }
}

class OneToOneMeetingScreen extends StatefulWidget {
  const OneToOneMeetingScreen({
    super.key,
    required this.thinker,
    required this.chatClient,
    required this.store,
    required this.onBack,
  });

  final MindProfile thinker;
  final ChatClient chatClient;
  final LocalStore store;
  final VoidCallback onBack;

  @override
  State<OneToOneMeetingScreen> createState() => _OneToOneMeetingScreenState();
}

class _OneToOneMeetingScreenState extends State<OneToOneMeetingScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<_DirectMessage> _messages = const [];
  String _conversationId = _newConversationId();
  String? _customPrompt;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant OneToOneMeetingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thinker.id != widget.thinker.id) {
      _controller.clear();
      setState(() {
        _messages = const [];
        _conversationId = _newConversationId();
        _error = null;
        _running = false;
        _customPrompt = null;
      });
      _loadPrompt();
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    final prompt =
        await widget.store.readSetting(_promptSettingKey(widget.thinker));
    if (!mounted) return;
    setState(
        () => _customPrompt = prompt?.trim().isEmpty == true ? null : prompt);
  }

  Future<void> _loadHistory() async {
    final thinkerId = widget.thinker.id;
    final sessions = await _readHistorySessions();
    final activeId = await widget.store
        .readSetting(_activeHistorySettingKey(widget.thinker));
    _DirectSession? activeSession;
    for (final session in sessions) {
      if (session.id == activeId) {
        activeSession = session;
        break;
      }
    }

    if (activeSession == null && sessions.isEmpty) {
      final legacy = _decodeDirectMessages(
        await widget.store.readSetting(_historySettingKey(widget.thinker)),
      );
      if (legacy.isNotEmpty) {
        activeSession = _DirectSession.fromMessages(
          id: _newConversationId(),
          messages: legacy,
        );
        await _writeHistorySessions([activeSession]);
        await widget.store.saveSetting(
          _activeHistorySettingKey(widget.thinker),
          activeSession.id,
        );
      }
    }

    activeSession ??= sessions.isNotEmpty ? sessions.first : null;
    if (!mounted || thinkerId != widget.thinker.id) return;
    setState(() {
      _conversationId = activeSession?.id ?? _newConversationId();
      _messages = activeSession?.messages ?? const [];
    });
    _jumpToBottom();
  }

  Future<List<_DirectSession>> _readHistorySessions() async {
    final raw =
        await widget.store.readSetting(_sessionsSettingKey(widget.thinker));
    return _decodeDirectSessions(raw);
  }

  Future<void> _writeHistorySessions(List<_DirectSession> sessions) async {
    final ordered = [...sessions]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await widget.store.saveSetting(
      _sessionsSettingKey(widget.thinker),
      jsonEncode(ordered.take(40).map((session) => session.toJson()).toList()),
    );
  }

  Future<void> _saveHistory([List<_DirectMessage>? messages]) async {
    final next = messages ?? _messages;
    if (next.isEmpty) return;
    final sessions = await _readHistorySessions();
    final session = _DirectSession.fromMessages(
      id: _conversationId,
      messages: next,
    );
    final filtered = sessions.where((item) => item.id != session.id).toList();
    await _writeHistorySessions([session, ...filtered]);
    await widget.store.saveSetting(
      _activeHistorySettingKey(widget.thinker),
      _conversationId,
    );
  }

  Future<void> _startNewChat() async {
    if (_messages.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start new chat?'),
          content: Text(
              'Your current chat with ${widget.thinker.name} will stay in History.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AgoraColors.ink,
                foregroundColor: Colors.white,
              ),
              child: const Text('New chat'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _saveHistory();
    }
    final nextId = _newConversationId();
    await widget.store.saveSetting(
      _activeHistorySettingKey(widget.thinker),
      nextId,
    );
    if (!mounted) return;
    setState(() {
      _conversationId = nextId;
      _messages = const [];
      _error = null;
    });
  }

  Future<void> _openHistory() async {
    final sessions = await _readHistorySessions();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => _HistoryDialog(
        thinker: widget.thinker,
        sessions: sessions,
        activeSessionId: _conversationId,
        onSelect: (session) async {
          await _saveHistory();
          await widget.store.saveSetting(
            _activeHistorySettingKey(widget.thinker),
            session.id,
          );
          if (!mounted) return;
          setState(() {
            _conversationId = session.id;
            _messages = session.messages;
            _error = null;
          });
          _jumpToBottom();
        },
      ),
    );
  }

  Future<void> _savePrompt(String prompt) async {
    final normalized = prompt.trim();
    await widget.store
        .saveSetting(_promptSettingKey(widget.thinker), normalized);
    if (!mounted) return;
    setState(() => _customPrompt = normalized.isEmpty ? null : normalized);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            normalized.isEmpty ? 'Prompt reset to default.' : 'Prompt saved.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _editPrompt() {
    showDialog<void>(
      context: context,
      builder: (context) => _PromptEditorDialog(
        thinker: widget.thinker,
        initialPrompt: _customPrompt ?? _systemPromptFor(widget.thinker),
        defaultPrompt: _systemPromptFor(widget.thinker),
        onSave: _savePrompt,
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _running) return;
    _controller.clear();
    final nextMessages = [
      ..._messages,
      _DirectMessage.you(text, DateTime.now()),
    ];
    setState(() {
      _error = null;
      _messages = nextMessages;
    });
    await _saveHistory(nextMessages);
    _jumpToBottom();
    await _requestThinkerReply(text, transcript: nextMessages);
  }

  Future<void> _requestThinkerReply(
    String userPrompt, {
    List<_DirectMessage>? transcript,
  }) async {
    if (!widget.chatClient.usesRealApi) {
      setState(() {
        _error =
            'Real LLM API is not configured. Rebuild/run with GEMMA_BASE_URL and GEMMA_MODEL to enable live 1:1 chat.';
      });
      return;
    }

    setState(() => _running = true);
    try {
      final messages = _promptMessagesFor(
        thinker: widget.thinker,
        transcript: transcript ?? _messages,
        userPrompt: userPrompt,
        customPrompt: _customPrompt,
      );
      var reply = '';
      var insertedReply = false;
      await for (final chunk in widget.chatClient.streamComplete(
        messages,
        temperature: _temperatureFor(widget.thinker),
        maxTokens: 260,
      )) {
        if (!mounted) return;
        reply = _cleanReply('$reply$chunk');
        setState(() {
          if (insertedReply && _messages.isNotEmpty) {
            _messages = [
              ..._messages.take(_messages.length - 1),
              _DirectMessage.thinker(reply, _messages.last.createdAt),
            ];
          } else {
            insertedReply = true;
            _messages = [
              ..._messages,
              _DirectMessage.thinker(reply, DateTime.now()),
            ];
          }
        });
        _jumpToBottom();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        await _saveHistory();
        setState(() => _running = false);
      }
      _jumpToBottom();
    }
  }

  void _quickAsk(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _send();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _cleanReply(String value) {
    final trimmed = value.trim();
    final marker = '${widget.thinker.name} (${widget.thinker.role}):';
    if (trimmed.startsWith(marker)) {
      return trimmed.substring(marker.length).trim();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 940;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth < 700 ? 14 : 24,
              14,
              constraints.maxWidth < 700 ? 14 : 24,
              110,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: compact
                    ? Column(
                        children: [
                          _ConversationPanel(
                            thinker: widget.thinker,
                            messages: _messages,
                            controller: _controller,
                            scrollController: _scrollController,
                            running: _running,
                            error: _error,
                            onBack: widget.onBack,
                            onEditPrompt: _editPrompt,
                            onStartNewChat: _startNewChat,
                            onOpenHistory: _openHistory,
                            onSend: _send,
                            onQuickAsk: _quickAsk,
                          ),
                          const SizedBox(height: 16),
                          _InsightPanel(thinker: widget.thinker),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ConversationPanel(
                              thinker: widget.thinker,
                              messages: _messages,
                              controller: _controller,
                              scrollController: _scrollController,
                              running: _running,
                              error: _error,
                              onBack: widget.onBack,
                              onEditPrompt: _editPrompt,
                              onStartNewChat: _startNewChat,
                              onOpenHistory: _openHistory,
                              onSend: _send,
                              onQuickAsk: _quickAsk,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 300,
                            child: _InsightPanel(thinker: widget.thinker),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({
    required this.thinker,
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.running,
    required this.error,
    required this.onBack,
    required this.onEditPrompt,
    required this.onStartNewChat,
    required this.onOpenHistory,
    required this.onSend,
    required this.onQuickAsk,
  });

  final MindProfile thinker;
  final List<_DirectMessage> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool running;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onEditPrompt;
  final VoidCallback onStartNewChat;
  final VoidCallback onOpenHistory;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height - 28,
      constraints: const BoxConstraints(minHeight: 660),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: AgoraShadows.panel,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to thinkers',
                ),
                const SizedBox(width: 10),
                ThinkerAvatar(
                    name: thinker.name, color: thinker.color, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(thinker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: displayStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('${thinker.role} · ${_lensFor(thinker)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle(
                              fontSize: 14,
                              color: thinker.color,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onStartNewChat,
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: 'New chat',
                ),
                IconButton(
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'History',
                ),
                IconButton(
                  onPressed: onEditPrompt,
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Edit thinker prompt',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 34),
            child: Row(
              children: [
                Expanded(child: Divider(color: AgoraColors.hair)),
                SizedBox(width: 12),
                AgoraChip(
                  label: 'Thinking about: AI social media product',
                  icon: Icons.auto_awesome_rounded,
                  backgroundColor: AgoraColors.canvas,
                ),
                SizedBox(width: 12),
                Expanded(child: Divider(color: AgoraColors.hair)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(56, 28, 56, 28),
              itemCount: messages.length + (running ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return _TypingBubble(thinker: thinker);
                }
                return _DirectBubble(
                    thinker: thinker, message: messages[index]);
              },
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 8),
              child: Text(error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle(fontSize: 12, color: AgoraColors.pink)),
            ),
          _ComposerDock(
            thinker: thinker,
            controller: controller,
            running: running,
            onSend: onSend,
            onQuickAsk: onQuickAsk,
          ),
        ],
      ),
    );
  }
}

class _DirectBubble extends StatelessWidget {
  const _DirectBubble({required this.thinker, required this.message});

  final MindProfile thinker;
  final _DirectMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            ThinkerAvatar(name: thinker.name, color: thinker.color, size: 38),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(message.timeLabel,
                      style: bodyStyle(fontSize: 12, color: AgoraColors.mute)),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 620),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                  decoration: BoxDecoration(
                    color: isUser ? AgoraColors.ink : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isUser ? AgoraColors.ink : AgoraColors.hair,
                    ),
                    boxShadow: AgoraShadows.card,
                  ),
                  child: MarkdownText(
                    text: message.text,
                    style: bodyStyle(fontSize: 15.5, height: 1.5),
                    color: isUser ? Colors.white : AgoraColors.ink2,
                    codeBackground: isUser
                        ? Colors.white.withValues(alpha: 0.14)
                        : AgoraColors.canvas.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            const ThinkerAvatar(
                name: 'You', size: 42, dark: true, showInitial: true),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.thinker});

  final MindProfile thinker;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          ThinkerAvatar(name: thinker.name, color: thinker.color, size: 38),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AgoraColors.hair),
              boxShadow: AgoraShadows.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: thinker.color,
                  ),
                ),
                const SizedBox(width: 10),
                Text('thinking...',
                    style: bodyStyle(fontSize: 13, color: AgoraColors.mute)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerDock extends StatelessWidget {
  const _ComposerDock({
    required this.thinker,
    required this.controller,
    required this.running,
    required this.onSend,
    required this.onQuickAsk,
  });

  final MindProfile thinker;
  final TextEditingController controller;
  final bool running;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickAsk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 0, 44, 26),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AgoraColors.hair),
          boxShadow: AgoraShadows.panel,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.enter): onSend,
                    },
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Ask ${thinker.name} anything...',
                      ),
                      style: bodyStyle(fontSize: 15, color: AgoraColors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AgoraColors.ink,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: running ? null : onSend,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    color: Colors.white,
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.help_outline_rounded,
                  label: 'Ask',
                  onTap: () => onQuickAsk(
                      'What is the clearest next product decision here?'),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.balance_rounded,
                  label: 'Challenge',
                  onTap: () => onQuickAsk(
                      'Challenge the weakest assumption in this idea.'),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Summarize',
                  onTap: () => onQuickAsk(
                      'Summarize this as one insight and one next action.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AgoraColors.inkSoft,
        backgroundColor: AgoraColors.canvas.withValues(alpha: 0.72),
        side: const BorderSide(color: AgoraColors.hair),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: bodyStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.thinker});

  final MindProfile thinker;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(22),
      backgroundColor: Colors.white.withValues(alpha: 0.78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: thinker.color, size: 18),
              const SizedBox(width: 8),
              Text('CURRENT INSIGHT',
                  style: bodyStyle(
                    fontSize: 12,
                    color: AgoraColors.inkSoft,
                    fontWeight: FontWeight.w900,
                  )),
            ],
          ),
          const SizedBox(height: 26),
          Center(child: _ArchMedallion(color: thinker.color)),
          const SizedBox(height: 26),
          Text(_insightTitle(thinker),
              style: displayStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(
            _insightBody(thinker),
            style:
                bodyStyle(fontSize: 14, height: 1.55, color: AgoraColors.ink2),
          ),
          const SizedBox(height: 22),
          const Divider(color: AgoraColors.hair),
          const SizedBox(height: 16),
          Text('KEY THEMES',
              style: bodyStyle(
                  fontSize: 12,
                  color: AgoraColors.inkSoft,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _themesFor(thinker)
                .map((theme) => AgoraChip(
                      label: theme,
                      backgroundColor: AgoraColors.canvas,
                      foregroundColor: thinker.color,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ThinkerProfileCard extends StatelessWidget {
  const _ThinkerProfileCard({
    required this.thinker,
    required this.onTap,
    required this.onDelete,
  });

  final MindProfile thinker;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      backgroundColor: Colors.white.withValues(alpha: 0.78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThinkerAvatar(name: thinker.name, color: thinker.color, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(thinker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: displayStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(thinker.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle(
                            fontSize: 12.5,
                            color: thinker.color,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                tooltip: 'Delete thinker',
                color: AgoraColors.mute,
                visualDensity: VisualDensity.compact,
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: AgoraColors.mute),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Text(
              thinker.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle(
                  fontSize: 13.5, color: AgoraColors.inkSoft, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _themesFor(thinker)
                .take(2)
                .map((theme) => AgoraChip(label: theme))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ArchMedallion extends StatelessWidget {
  const _ArchMedallion({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AgoraColors.canvas.withValues(alpha: 0.62),
      ),
      child: CustomPaint(painter: _ArchPainter(color)),
    );
  }
}

class _ArchPainter extends CustomPainter {
  const _ArchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = color.withValues(alpha: 0.58);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AgoraColors.gold.withValues(alpha: 0.22);
    final left = size.width * 0.36;
    final right = size.width * 0.64;
    final top = size.height * 0.24;
    final bottom = size.height * 0.78;
    final path = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + 18)
      ..arcToPoint(Offset(right, top + 18), radius: const Radius.circular(22))
      ..lineTo(right, bottom);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 2.6,
        Paint()..color = AgoraColors.gold);
    final sparkle = Path()
      ..moveTo(size.width * 0.77, size.height * 0.48)
      ..lineTo(size.width * 0.80, size.height * 0.53)
      ..lineTo(size.width * 0.85, size.height * 0.56)
      ..lineTo(size.width * 0.80, size.height * 0.59)
      ..lineTo(size.width * 0.77, size.height * 0.64)
      ..lineTo(size.width * 0.74, size.height * 0.59)
      ..lineTo(size.width * 0.69, size.height * 0.56)
      ..lineTo(size.width * 0.74, size.height * 0.53)
      ..close();
    canvas.drawPath(sparkle, Paint()..color = AgoraColors.gold);
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PromptEditorDialog extends StatefulWidget {
  const _PromptEditorDialog({
    required this.thinker,
    required this.initialPrompt,
    required this.defaultPrompt,
    required this.onSave,
  });

  final MindProfile thinker;
  final String initialPrompt;
  final String defaultPrompt;
  final ValueChanged<String> onSave;

  @override
  State<_PromptEditorDialog> createState() => _PromptEditorDialogState();
}

class _PromptEditorDialogState extends State<_PromptEditorDialog> {
  late final TextEditingController _controller;
  final _editorScrollController = ScrollController();
  bool _showDefaultPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _loadDefault() {
    _controller.value = TextEditingValue(
      text: widget.defaultPrompt,
      selection: TextSelection.collapsed(offset: widget.defaultPrompt.length),
    );
  }

  void _clearEditor() {
    _controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: height < 760 ? height - 56 : 720,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ThinkerAvatar(
                    name: widget.thinker.name,
                    color: widget.thinker.color,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit ${widget.thinker.name} prompt',
                            style: displayStyle(
                                fontSize: 19, fontWeight: FontWeight.w800)),
                        Text('Saved locally in this browser/device.',
                            style: bodyStyle(
                                fontSize: 12.5, color: AgoraColors.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AgoraColors.canvas.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AgoraColors.hair),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(
                          () => _showDefaultPreview = !_showDefaultPreview),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.notes_rounded,
                                size: 18, color: AgoraColors.inkSoft),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Default prompt preview',
                                  style: bodyStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AgoraColors.inkSoft)),
                            ),
                            TextButton(
                              onPressed: _loadDefault,
                              child: const Text('Load default into editor'),
                            ),
                            Icon(_showDefaultPreview
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded),
                          ],
                        ),
                      ),
                    ),
                    if (_showDefaultPreview)
                      Container(
                        height: 120,
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            widget.defaultPrompt,
                            style: bodyStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: AgoraColors.inkSoft),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Scrollbar(
                  controller: _editorScrollController,
                  thumbVisibility: true,
                  child: TextField(
                    controller: _controller,
                    scrollController: _editorScrollController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 18,
                    maxLines: 18,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    decoration: InputDecoration(
                      hintText:
                          'Write a concise system prompt for this thinker...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AgoraColors.hair),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AgoraColors.hair),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: widget.thinker.color),
                      ),
                    ),
                    style: bodyStyle(fontSize: 13.5, height: 1.42),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _loadDefault,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Restore default'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearEditor,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      widget.onSave('');
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear saved'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onSave(_controller.text);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save prompt'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AgoraColors.ink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  const _HistoryDialog({
    required this.thinker,
    required this.sessions,
    required this.activeSessionId,
    required this.onSelect,
  });

  final MindProfile thinker;
  final List<_DirectSession> sessions;
  final String activeSessionId;
  final ValueChanged<_DirectSession> onSelect;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${thinker.name} history',
                      style: displayStyle(
                          fontSize: 21, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No saved chats yet.',
                      style: bodyStyle(color: AgoraColors.inkSoft),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final active = session.id == activeSessionId;
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelect(session);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: active
                                ? thinker.color.withValues(alpha: 0.10)
                                : AgoraColors.canvas.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? thinker.color : AgoraColors.hair,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                color:
                                    active ? thinker.color : AgoraColors.mute,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(session.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: bodyStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AgoraColors.ink)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${session.messageCount} messages · ${session.updatedLabel}',
                                      style: bodyStyle(
                                          fontSize: 12,
                                          color: AgoraColors.inkSoft),
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
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _promptSettingKey(MindProfile thinker) {
  return 'one_to_one.prompt.${thinker.id}.v1';
}

String _historySettingKey(MindProfile thinker) {
  return 'one_to_one.history.${thinker.id}.v1';
}

String _sessionsSettingKey(MindProfile thinker) {
  return 'one_to_one.sessions.${thinker.id}.v1';
}

String _activeHistorySettingKey(MindProfile thinker) {
  return 'one_to_one.active_session.${thinker.id}.v1';
}

String _newConversationId() {
  return 'chat_${DateTime.now().microsecondsSinceEpoch}';
}

class _DirectMessage {
  const _DirectMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;

  String get timeLabel {
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final suffix = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  factory _DirectMessage.thinker(String text, DateTime createdAt) {
    return _DirectMessage(text: text, isUser: false, createdAt: createdAt);
  }

  factory _DirectMessage.you(String text, DateTime createdAt) {
    return _DirectMessage(text: text, isUser: true, createdAt: createdAt);
  }

  factory _DirectMessage.fromJson(Map<String, dynamic> json) {
    return _DirectMessage(
      text: json['text']?.toString() ?? '',
      isUser: json['isUser'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        _intValue(json['createdAt']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class _DirectSession {
  const _DirectSession({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<_DirectMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get messageCount => messages.length;

  String get title {
    _DirectMessage? firstUser;
    for (final message in messages) {
      if (message.isUser) {
        firstUser = message;
        break;
      }
    }
    final source = firstUser?.text ??
        (messages.isEmpty ? 'New chat' : messages.first.text);
    final normalized = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    if (normalized.length <= 72) return normalized;
    return '${normalized.substring(0, 72)}...';
  }

  String get updatedLabel {
    final hour = updatedAt.hour % 12 == 0 ? 12 : updatedAt.hour % 12;
    final minute = updatedAt.minute.toString().padLeft(2, '0');
    final suffix = updatedAt.hour >= 12 ? 'PM' : 'AM';
    return '${updatedAt.month}/${updatedAt.day} $hour:$minute $suffix';
  }

  factory _DirectSession.fromMessages({
    required String id,
    required List<_DirectMessage> messages,
  }) {
    final now = DateTime.now();
    return _DirectSession(
      id: id,
      messages: messages,
      createdAt: messages.isEmpty ? now : messages.first.createdAt,
      updatedAt: messages.isEmpty ? now : messages.last.createdAt,
    );
  }

  factory _DirectSession.fromJson(Map<String, dynamic> json) {
    return _DirectSession(
      id: json['id']?.toString() ?? _newConversationId(),
      messages: _decodeDirectMessages(jsonEncode(json['messages'] ?? [])),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(_intValue(json['createdAt'])),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(_intValue(json['updatedAt'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

List<_DirectSession> _decodeDirectSessions(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((row) => _DirectSession.fromJson(Map<String, dynamic>.from(row)))
        .where((session) => session.messages.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  } catch (_) {
    return const [];
  }
}

List<_DirectMessage> _decodeDirectMessages(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((row) => _DirectMessage.fromJson(Map<String, dynamic>.from(row)))
        .where((message) => message.text.trim().isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ??
      DateTime.now().millisecondsSinceEpoch;
}

List<LlmChatMessage> _promptMessagesFor({
  required MindProfile thinker,
  required List<_DirectMessage> transcript,
  required String userPrompt,
  String? customPrompt,
}) {
  final recent = transcript.length > 10
      ? transcript.sublist(transcript.length - 10)
      : transcript;
  final promptAlreadyInTranscript =
      recent.isNotEmpty && recent.last.isUser && recent.last.text == userPrompt;
  return [
    LlmChatMessage(
      role: 'system',
      content: customPrompt?.trim().isNotEmpty == true
          ? customPrompt!.trim()
          : thinker.persona.trim().isNotEmpty
              ? thinker.persona.trim()
              : _systemPromptFor(thinker),
    ),
    ...recent.map(
      (message) => LlmChatMessage(
        role: message.isUser ? 'user' : 'assistant',
        content: message.text,
      ),
    ),
    if (!promptAlreadyInTranscript)
      LlmChatMessage(role: 'user', content: userPrompt),
  ];
}

String _systemPromptFor(MindProfile thinker) {
  final base = '''
You are ${thinker.name} inside Mind Agora's one-to-one meeting mode.
This is a real live chat, not a scripted demo. Respond directly to the user's latest message.

Product context:
- The user is designing an AI social media / learning product.
- The product goal is to help users think more clearly, escape echo chambers, and convert conversations into insight and action.
- Keep answers concise: 2-4 short paragraphs, no bullet list unless the user asks for one.
- Preserve your persona. Do not mention that you are an AI model. Do not roleplay multiple people.
- Be concrete: give one product implication, one challenge or question, and one next action when useful.
''';

  final persona = switch (thinker.id) {
    'monet' => '''
Persona prompt:
You are Monet as an advocate and creative lens. Think in light, atmosphere, attention, and composition. Push the user to design calm social spaces that make reflection feel natural. Prefer language about clarity, texture, rhythm, and designing a studio rather than a stage.
Avoid generic growth-hacking language. Your recurring question: does this interface help people see more clearly?
''',
    'socrates' => '''
Persona prompt:
You are Socrates as a questioner. Lead with disciplined questions, expose hidden assumptions, and avoid giving the user premature certainty. Use short chains of reasoning and one sharp question at a time.
Your recurring question: what belief is the user accepting without examination?
''',
    'laozi' => '''
Persona prompt:
You are Laozi as a harmonizer. Favor simplicity, non-coercive design, quiet timing, and low-friction pauses. Be skeptical of overbuilt systems and anxious optimization.
Your recurring question: what can the product remove so the user can act with less force?
''',
    'nietzsche' => '''
Persona prompt:
You are Nietzsche as a provocateur. Challenge comfort, borrowed values, performative virtue, and herd behavior. Be intense but useful; do not become theatrical or cruel.
Your recurring question: is this product helping users choose their own values, or merely decorate conformity?
''',
    'marie_curie' => '''
Persona prompt:
You are Marie Curie as an empiricist. Turn claims into experiments, measurements, and disciplined iteration. Ask for evidence, longitudinal signals, and mechanisms.
Your recurring question: what would prove the user actually learned or changed behavior?
''',
    'plato' => '''
Persona prompt:
You are Plato as a form-seeker. Clarify definitions, ideals, structures, and the difference between appearance and truth. Help the user shape a coherent product philosophy before features.
Your recurring question: what is the form of a good AI social product?
''',
    'wang_yangming' => '''
Persona prompt:
You are Wang Yangming as an action lens. Join knowing and doing. Push every insight toward a small visible action and a test in lived practice.
Your recurring question: what tiny action would make this knowledge real today?
''',
    'feynman' => '''
Persona prompt:
You are Richard Feynman as a mechanism explainer. Strip abstractions down to simple causal mechanisms, analogies, and tests. Prefer clarity over elegance.
Your recurring question: can the user explain the loop simply enough to build and test it?
''',
    _ => '''
Persona prompt:
Use this thinker's profile as your guide:
Name: ${thinker.name}
Role: ${thinker.role}
Description: ${thinker.description}
''',
  };

  return '$base\n$persona'.trim();
}

double _temperatureFor(MindProfile thinker) {
  return switch (thinker.id) {
    'monet' => 0.78,
    'nietzsche' => 0.82,
    'socrates' => 0.66,
    'marie_curie' => 0.58,
    'feynman' => 0.54,
    _ => 0.68,
  };
}

String _lensFor(MindProfile thinker) {
  return switch (thinker.id) {
    'monet' => 'Creative Lens',
    'socrates' => 'Questioning Lens',
    'laozi' => 'Calm Systems Lens',
    'nietzsche' => 'Value Lens',
    'marie_curie' => 'Evidence Lens',
    'plato' => 'Form Lens',
    'wang_yangming' => 'Action Lens',
    'feynman' => 'Mechanism Lens',
    _ => 'Reflection Lens',
  };
}

String _insightTitle(MindProfile thinker) {
  return switch (thinker.id) {
    'monet' => 'Design for clarity, not consumption.',
    'marie_curie' => 'Make learning measurable.',
    'socrates' => 'A better feed asks better questions.',
    'laozi' => 'The pause is the product.',
    'nietzsche' => 'Challenge the inherited desire.',
    _ => 'Turn conversation into action.',
  };
}

String _insightBody(MindProfile thinker) {
  return switch (thinker.id) {
    'monet' =>
      'An AI social product should cultivate reflection and learning through gentle prompts, meaningful summaries, and an environment that values thought over speed.',
    'marie_curie' =>
      'The product story gets stronger when insight becomes observable: saved decisions, changed plans, and reflective returns matter more than raw engagement.',
    'socrates' =>
      'If the feed helps users inspect assumptions before reacting, it becomes a learning environment instead of another attention market.',
    'laozi' =>
      'A quieter social loop can still be powerful: reduce friction for pausing, reframing, and acting without turning growth into pressure.',
    'nietzsche' =>
      'The product should help users distinguish authentic ambition from borrowed performance, then act from the former.',
    _ =>
      'A useful one-to-one meeting should compress discussion into one sharper lens and one practical next move.',
  };
}

List<String> _themesFor(MindProfile thinker) {
  return switch (thinker.id) {
    'monet' => ['#anti-echo', '#education', '#slow-social'],
    'socrates' => ['#questions', '#clarity', '#assumptions'],
    'laozi' => ['#pause', '#simplicity', '#calm-loop'],
    'nietzsche' => ['#values', '#challenge', '#agency'],
    'marie_curie' => ['#evidence', '#learning', '#metrics'],
    'plato' => ['#forms', '#structure', '#truth'],
    'wang_yangming' => ['#action', '#knowing', '#practice'],
    'feynman' => ['#mechanism', '#explain', '#test'],
    _ => ['#reflection', '#focus', '#action'],
  };
}

const _thinkerPalette = <Color>[
  AgoraColors.accent,
  AgoraColors.violet,
  AgoraColors.pink,
  AgoraColors.green,
  Color(0xFFA35A2E),
  Color(0xFF9C7325),
  Color(0xFF264FB1),
];

const _importExample = '''[
  {
    "name": "Ada Lovelace",
    "role": "Systems Imaginator",
    "description": "Connect poetic imagination with rigorous machinery and product systems.",
    "prompt": "You are Ada Lovelace inside Mind Agora. Help the user connect imagination, computation, and practical system design.",
    "color": "#7B6AE0"
  }
]''';

List<MindProfile> _filterThinkersByName(
  List<MindProfile> thinkers,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return thinkers;
  return thinkers
      .where((thinker) => thinker.name.toLowerCase().contains(normalized))
      .toList();
}

List<MindProfile> _oneToOneThinkers({
  List<MindProfile> customThinkers = const [],
  Set<String> deletedThinkerIds = const {},
}) {
  final byId = <String, MindProfile>{
    for (final thinker in customThinkers) thinker.id: thinker,
  };
  return byId.values
      .where((thinker) => !deletedThinkerIds.contains(thinker.id))
      .toList();
}

Future<void> _deleteThinkerLocalData(
  LocalStore store,
  MindProfile thinker,
) async {
  await store.saveSetting(_promptSettingKey(thinker), '');
  await store.saveSetting(_historySettingKey(thinker), '[]');
  await store.saveSetting(_sessionsSettingKey(thinker), '[]');
  await store.saveSetting(_activeHistorySettingKey(thinker), '');
}

List<MindProfile> _parseImportedThinkers(String raw) {
  final decoded = jsonDecode(raw);
  final rows = decoded is List ? decoded : [decoded];
  return rows
      .whereType<Map>()
      .map((row) => _thinkerFromImport(Map<String, dynamic>.from(row)))
      .toList();
}

MindProfile _thinkerFromImport(Map<String, dynamic> json) {
  final name = _stringValue(json['name']);
  final prompt =
      _stringValue(json['prompt'] ?? json['persona'] ?? json['systemPrompt']);
  if (name.isEmpty || prompt.isEmpty) {
    throw const FormatException('Each thinker needs name and prompt.');
  }
  final id = _stringValue(json['id']).isEmpty
      ? _idFromName(name)
      : _idFromName(_stringValue(json['id']));
  final handle = _stringValue(json['handle']).isEmpty
      ? '@$id'
      : _stringValue(json['handle']);
  return MindProfile(
    id: id,
    name: name,
    handle: handle,
    role: _stringValue(json['role'] ?? json['roleFunction']).isEmpty
        ? 'Custom thinker'
        : _stringValue(json['role'] ?? json['roleFunction']),
    description: _stringValue(json['description'] ?? json['bio']).isEmpty
        ? _descriptionFromPrompt(prompt)
        : _stringValue(json['description'] ?? json['bio']),
    persona: prompt,
    color: _colorFromValue(json['color'], id),
  );
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

String _descriptionFromPrompt(String prompt) {
  final normalized = prompt
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .join(' ');
  if (normalized.length <= 132) return normalized;
  return '${normalized.substring(0, 132)}...';
}

String _idFromName(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'custom_thinker' : normalized;
}

Color _colorFromValue(Object? value, String seed) {
  if (value is int) return Color(value);
  final text = value?.toString().trim() ?? '';
  if (text.startsWith('#')) {
    final hex = text.substring(1);
    final parsed = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return _thinkerPalette[seed.hashCode.abs() % _thinkerPalette.length];
}
