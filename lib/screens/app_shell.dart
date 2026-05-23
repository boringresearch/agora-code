import 'package:flutter/material.dart';

import '../llm/llm_client.dart';
import '../models/models.dart';
import '../storage/local_store.dart';
import '../widgets/agora_background.dart';
import '../widgets/nav.dart';
import 'home_screen.dart';
import 'meetings_screen.dart';
import 'one_to_one_screen.dart';
import 'placeholder_screen.dart';
import 'room_screen.dart';
import 'settings_screen.dart';
import 'think_room_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.chatClient,
  });

  final LocalStore store;
  final ChatClient chatClient;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _selected = AppSection.home;
  bool _liveRoomOpen = false;
  RoomMode _roomMode = RoomMode.complex;
  RoomSession? _draftSession;
  MindProfile? _oneToOneMind;

  void _select(AppSection section) {
    setState(() {
      _selected = section;
      if (section != AppSection.think) {
        _liveRoomOpen = false;
      }
      _oneToOneMind = null;
    });
  }

  void _openPlanner() {
    setState(() {
      _selected = AppSection.think;
      _liveRoomOpen = false;
      _draftSession = null;
      _oneToOneMind = null;
    });
  }

  void _openRoom([RoomMode mode = RoomMode.complex, RoomSession? session]) {
    setState(() {
      _selected = AppSection.think;
      _roomMode = mode;
      _draftSession = session;
      _liveRoomOpen = true;
      _oneToOneMind = null;
    });
  }

  void _openOneToOne(MindProfile thinker) {
    setState(() {
      _selected = AppSection.thinkers;
      _liveRoomOpen = false;
      _oneToOneMind = thinker;
    });
  }

  void _openSavedRoom(RoomSession session) {
    _openRoom(_modeForSession(session), session);
  }

  RoomMode _modeForSession(RoomSession session) {
    if (session.runtimeMode == RoomMode.singlePrompt.label ||
        session.runtimeMode == RoomMode.singlePrompt.name) {
      return RoomMode.singlePrompt;
    }
    return RoomMode.complex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AgoraBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSideNav = constraints.maxWidth >= 820;
            final content = _buildContent();
            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSideNav)
                      SideNav(
                        selected: _selected,
                        onSelected: _select,
                        onProfileTap: () => _select(AppSection.settings),
                      ),
                    Expanded(child: content),
                  ],
                ),
                if (!showSideNav)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: MobileBottomNav(
                        selected: _selected, onSelected: _select),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_selected) {
      AppSection.home => HomeScreen(
          store: widget.store,
          onOpenRoom: _openPlanner,
        ),
      AppSection.meetings => MeetingsScreen(
          store: widget.store,
          onNewRoom: _openPlanner,
          onOpenRoom: _openSavedRoom),
      AppSection.think => _liveRoomOpen
          ? LiveRoomScreen(
              initialMode: _roomMode,
              initialSession: _draftSession,
              store: widget.store,
              chatClient: widget.chatClient,
              onBackToPlanner: () => setState(() => _liveRoomOpen = false),
            )
          : ThinkRoomScreen(store: widget.store, onBegin: _openRoom),
      AppSection.selfReflection => const PlaceholderScreen(
          title: 'Self-reflection',
          subtitle:
              'Journal prompts, memory cards, and private reflections will live here.',
          icon: Icons.explore_outlined,
        ),
      AppSection.saved => const PlaceholderScreen(
          title: 'Saved',
          subtitle: 'Collected quotes, thinker replies, and meeting summaries.',
          icon: Icons.bookmark_border_rounded,
        ),
      AppSection.quotes => const PlaceholderScreen(
          title: 'Quotes',
          subtitle:
              'A living quote garden from your council and the public feed.',
          icon: Icons.format_quote_rounded,
        ),
      AppSection.thinkers => _oneToOneMind == null
          ? ThinkersScreen(
              store: widget.store,
              onStartConversation: _openOneToOne,
            )
          : OneToOneMeetingScreen(
              thinker: _oneToOneMind!,
              chatClient: widget.chatClient,
              store: widget.store,
              onBack: () => setState(() => _oneToOneMind = null),
            ),
      AppSection.collections => const PlaceholderScreen(
          title: 'Collections',
          subtitle: 'Bundle memories into themes and study paths.',
          icon: Icons.library_books_outlined,
        ),
      AppSection.notifications => const PlaceholderScreen(
          title: 'Notifications',
          subtitle: 'Mentions, thinker nudges, and room updates.',
          icon: Icons.notifications_none_rounded,
        ),
      AppSection.messages => const PlaceholderScreen(
          title: 'Messages',
          subtitle:
              'Private conversations with thinkers and invited collaborators.',
          icon: Icons.mail_outline_rounded,
        ),
      AppSection.settings => SettingsScreen(
          store: widget.store,
          chatClient: widget.chatClient,
        ),
    };
  }
}
