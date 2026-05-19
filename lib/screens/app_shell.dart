import 'package:flutter/material.dart';

import '../llm/llm_client.dart';
import '../models/models.dart';
import '../storage/local_store.dart';
import '../widgets/agora_background.dart';
import '../widgets/nav.dart';
import 'home_screen.dart';
import 'meetings_screen.dart';
import 'placeholder_screen.dart';
import 'room_screen.dart';
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

  void _select(AppSection section) {
    setState(() {
      _selected = section;
      if (section != AppSection.think) {
        _liveRoomOpen = false;
      }
    });
  }

  void _openRoom([RoomMode mode = RoomMode.complex]) {
    setState(() {
      _selected = AppSection.think;
      _roomMode = mode;
      _liveRoomOpen = true;
    });
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
                      SideNav(selected: _selected, onSelected: _select),
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
          onOpenRoom: () => _openRoom(RoomMode.complex),
        ),
      AppSection.meetings => MeetingsScreen(
          store: widget.store, onOpenRoom: () => _openRoom(_roomMode)),
      AppSection.think => _liveRoomOpen
          ? LiveRoomScreen(
              initialMode: _roomMode,
              store: widget.store,
              chatClient: widget.chatClient,
              onBackToPlanner: () => setState(() => _liveRoomOpen = false),
            )
          : ThinkRoomScreen(onBegin: _openRoom),
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
      AppSection.thinkers => const PlaceholderScreen(
          title: 'Thinkers',
          subtitle: 'Profiles, lenses, voice packs, and relationship history.',
          icon: Icons.groups_2_outlined,
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
    };
  }
}
