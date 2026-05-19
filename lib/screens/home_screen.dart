import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/models.dart';
import '../theme/agora_theme.dart';
import '../widgets/logo.dart';
import '../widgets/post_card.dart';
import '../widgets/soft_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenRoom});

  final VoidCallback onOpenRoom;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<FeedPost> _posts = List<FeedPost>.from(feedPosts);

  void _addPost(String body) {
    setState(() {
      _posts.insert(
        0,
        FeedPost(
          id: 'user_post_${DateTime.now().microsecondsSinceEpoch}',
          author: 'You',
          handle: '@you',
          timeLabel: 'now',
          body: body,
          avatarColor: AgoraColors.ink,
          actionLabel: 'Ask a thinker',
        ),
      );
    });
  }

  void _addComment(String postId, String body) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index < 0) return;
      final post = _posts[index];
      _posts[index] = post.copyWith(
        replies: post.replies + 1,
        comments: [
          ...post.comments,
          FeedComment(
            id: 'comment_${DateTime.now().microsecondsSinceEpoch}',
            author: 'You',
            handle: '@you',
            body: body,
            timeLabel: 'now',
          ),
        ],
      );
    });
  }

  void _deletePost(String postId) {
    setState(() {
      _posts.removeWhere((post) => post.id == postId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post deleted.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    constraints.maxWidth < 820 ? 16 : 28,
                    18,
                    showRightRail ? 18 : 28,
                    96,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopTabs(compact: constraints.maxWidth < 720),
                          const SizedBox(height: 18),
                          ComposerCard(onPost: _addPost),
                          const SizedBox(height: 22),
                          ..._posts.map(
                            (post) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: PostCard(
                                post: post,
                                onAskThinker: widget.onOpenRoom,
                                onReply: (body) => _addComment(post.id, body),
                                onDelete: () => _deletePost(post.id),
                              ),
                            ),
                          ),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon:
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                              label: const Text('Load more'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AgoraColors.ink,
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AgoraColors.hair),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999)),
                              ),
                            ),
                          ),
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
                    padding: const EdgeInsets.fromLTRB(2, 18, 20, 96),
                    child: _RightRail(onOpenRoom: widget.onOpenRoom),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tabs = ['For You', 'Following', 'Questions', 'Quotes'];
    return Row(
      children: [
        if (compact) const AgoraLogo(showText: false, iconSize: 34),
        if (compact) const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final active = entry.key == 3;
                return Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Column(
                    children: [
                      Text(
                        entry.value,
                        style: bodyStyle(
                          fontWeight: FontWeight.w800,
                          color: active ? AgoraColors.ink : AgoraColors.mute,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: active ? 64 : 0,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: active ? AgoraColors.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 18),
        if (!compact)
          SizedBox(
            width: 300,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: AgoraColors.mute),
                hintText: 'Search Mind Agora',
              ),
              style: bodyStyle(fontSize: 14),
            ),
          ),
        const SizedBox(width: 12),
        SoftIconButton(icon: Icons.auto_awesome_outlined, onPressed: () {}),
        const SizedBox(width: 10),
        SoftIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: () {},
            badge: true),
      ],
    );
  }
}

class _RightRail extends StatelessWidget {
  const _RightRail({required this.onOpenRoom});

  final VoidCallback onOpenRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Converse with great minds',
                      style: displayStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Icon(Icons.person_add_alt_1_outlined,
                      size: 18, color: AgoraColors.mute),
                ],
              ),
              const SizedBox(height: 14),
              ...railThinkers.map(
                (thinker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ThinkerRailTile(thinker: thinker),
                ),
              ),
              const Divider(height: 1, color: AgoraColors.hair),
              TextButton(
                onPressed: onOpenRoom,
                style: TextButton.styleFrom(foregroundColor: AgoraColors.ink),
                child: const Row(
                  children: [
                    Text('View all thinkers'),
                    Spacer(),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('AI prompts for you',
                      style: displayStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Icon(Icons.auto_awesome_outlined,
                      size: 18, color: AgoraColors.mute),
                ],
              ),
              const SizedBox(height: 14),
              ...promptSuggestions.map(
                (prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PromptTile(prompt: prompt),
                ),
              ),
              const Divider(height: 1, color: AgoraColors.hair),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AgoraColors.ink),
                child: const Row(
                  children: [
                    Text('View all prompts'),
                    Spacer(),
                    Icon(Icons.arrow_forward_rounded, size: 16)
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Active conversations',
                      style: displayStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('View all',
                      style: bodyStyle(
                          fontSize: 12,
                          color: AgoraColors.mute,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 14),
              ...activeConversations.map((conv) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: onOpenRoom,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: conv.color, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              conv.title.isEmpty
                                  ? '?'
                                  : conv.title.substring(0, 1),
                              style: bodyStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conv.title,
                                  style: bodyStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AgoraColors.ink)),
                              Text(
                                'With ${conv.withWhom} · ${conv.messages} messages',
                                style: bodyStyle(
                                    fontSize: 12, color: AgoraColors.mute),
                              ),
                            ],
                          ),
                        ),
                        Text(conv.timeLabel,
                            style: bodyStyle(
                                fontSize: 12, color: AgoraColors.mute)),
                      ],
                    ),
                  ),
                );
              }),
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
              Text('Start a Thinking Room',
                  style: displayStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Invite minds, draft agenda, and turn a fuzzy question into an action map.',
                style: bodyStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.45),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenRoom,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Open room'),
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
