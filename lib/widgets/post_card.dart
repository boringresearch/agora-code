import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/agora_theme.dart';
import 'avatar.dart';
import 'chip.dart';
import 'soft_card.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onAskThinker,
    this.onReply,
  });

  final FeedPost post;
  final VoidCallback? onAskThinker;
  final ValueChanged<String>? onReply;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _replyController = TextEditingController();
  bool _replying = false;
  bool _canSubmitReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _toggleReply() {
    setState(() => _replying = !_replying);
  }

  void _submitReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    widget.onReply?.call(text);
    _replyController.clear();
    setState(() {
      _replying = false;
      _canSubmitReply = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThinkerAvatar(
                name: post.author,
                size: 46,
                color: post.avatarColor,
                dark: !post.verified,
                showInitial: !post.verified,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.author,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle(
                              fontWeight: FontWeight.w800,
                              color: AgoraColors.ink,
                            ),
                          ),
                        ),
                        if (post.verified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AgoraColors.accent),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          '${post.handle} · ${post.timeLabel}',
                          style:
                              bodyStyle(fontSize: 12, color: AgoraColors.mute),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
                color: AgoraColors.mute,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.body,
            style:
                bodyStyle(fontSize: 15, height: 1.55, color: AgoraColors.ink2),
          ),
          if (post.replyAuthor != null && post.replyBody != null) ...[
            const SizedBox(height: 14),
            _InlineReply(
              author: post.replyAuthor!,
              timeLabel: 'now',
              body: post.replyBody!,
              avatarColor: AgoraColors.gold,
            ),
          ],
          ...post.comments.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _InlineReply(
                author: comment.author,
                timeLabel: comment.timeLabel,
                body: comment.body,
                handle: comment.handle,
                darkAvatar: true,
              ),
            ),
          ),
          if (_replying) ...[
            const SizedBox(height: 14),
            _ReplyComposer(
              controller: _replyController,
              canSubmit: _canSubmitReply,
              onChanged: (value) =>
                  setState(() => _canSubmitReply = value.trim().isNotEmpty),
              onCancel: _toggleReply,
              onSubmit: _submitReply,
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AgoraColors.hair),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PostAction(
                  icon: Icons.favorite_border_rounded, label: 'Reflect'),
              _PostAction(icon: Icons.bookmark_border_rounded, label: 'Save'),
              _PostAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: _replying ? 'Close reply' : 'Reply',
                onPressed: widget.onReply == null ? null : _toggleReply,
              ),
              _PostAction(icon: Icons.share_outlined, label: 'Share'),
              const SizedBox(width: 8),
              Text('${post.likes} reflections',
                  style: bodyStyle(fontSize: 12, color: AgoraColors.mute)),
              Text('${post.replies} replies',
                  style: bodyStyle(fontSize: 12, color: AgoraColors.mute)),
              if (post.actionLabel != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onAskThinker,
                    icon: const Icon(Icons.question_answer_outlined, size: 16),
                    label: Text(post.actionLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: AgoraColors.ink,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AgoraColors.hair),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      textStyle:
                          bodyStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineReply extends StatelessWidget {
  const _InlineReply({
    required this.author,
    required this.timeLabel,
    required this.body,
    this.handle,
    this.avatarColor = AgoraColors.gold,
    this.darkAvatar = false,
  });

  final String author;
  final String timeLabel;
  final String body;
  final String? handle;
  final Color avatarColor;
  final bool darkAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AgoraColors.hair2, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThinkerAvatar(
            name: author,
            size: 34,
            color: avatarColor,
            dark: darkAvatar,
            showInitial: darkAvatar,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle(
                            fontWeight: FontWeight.w800,
                            color: AgoraColors.ink),
                      ),
                    ),
                    if (handle != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          handle!,
                          overflow: TextOverflow.ellipsis,
                          style:
                              bodyStyle(fontSize: 11, color: AgoraColors.mute),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(timeLabel,
                        style:
                            bodyStyle(fontSize: 11, color: AgoraColors.mute)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: bodyStyle(fontSize: 13.5, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.canSubmit,
    required this.onChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool canSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AgoraColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgoraColors.hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: ThinkerAvatar(name: 'You', size: 34, dark: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              onChanged: onChanged,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintStyle: bodyStyle(fontSize: 13.5, color: AgoraColors.mute),
              ),
              style: bodyStyle(fontSize: 13.5, color: AgoraColors.ink),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
            color: AgoraColors.mute,
            tooltip: 'Cancel comment',
          ),
          FilledButton(
            onPressed: canSubmit ? onSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AgoraColors.ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AgoraColors.hair2,
              disabledForegroundColor: AgoraColors.mute,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Comment'),
          ),
        ],
      ),
    );
  }
}

class ComposerCard extends StatefulWidget {
  const ComposerCard({super.key, this.onPost});

  final ValueChanged<String>? onPost;

  @override
  State<ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<ComposerCard> {
  final _controller = TextEditingController();
  bool _canSubmit = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitPost() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onPost?.call(text);
    _controller.clear();
    setState(() => _canSubmit = false);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const ThinkerAvatar(name: 'You', size: 40, dark: true),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  onChanged: (value) =>
                      setState(() => _canSubmit = value.trim().isNotEmpty),
                  decoration: InputDecoration(
                    hintText: 'Share a question, quote, or reflection...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: bodyStyle(fontSize: 15, color: AgoraColors.mute),
                  ),
                  style: bodyStyle(fontSize: 15, color: AgoraColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AgoraColors.hair),
          const SizedBox(height: 10),
          Row(
            children: [
              const _ComposerAction(icon: Icons.image_outlined, label: 'Image'),
              const _ComposerAction(
                  icon: Icons.format_quote_rounded, label: 'Quote'),
              const _ComposerAction(
                  icon: Icons.bar_chart_rounded, label: 'Poll'),
              const _ComposerAction(
                  icon: Icons.description_outlined, label: 'Note'),
              const _ComposerAction(
                  icon: Icons.add_reaction_outlined, label: 'Prompt'),
              const Spacer(),
              FilledButton(
                onPressed:
                    widget.onPost != null && _canSubmit ? _submitPost : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AgoraColors.ink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AgoraColors.hair2,
                  disabledForegroundColor: AgoraColors.mute,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: AgoraColors.inkSoft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: bodyStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({required this.icon, required this.label, this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AgoraColors.inkSoft,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textStyle: bodyStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PromptTile extends StatelessWidget {
  const PromptTile({super.key, required this.prompt});

  final PromptSuggestion prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgoraColors.hair),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: prompt.color, shape: BoxShape.circle),
            child: Icon(prompt.icon, size: 18, color: AgoraColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(prompt.text,
                style: bodyStyle(
                    fontSize: 13.5, color: AgoraColors.ink2, height: 1.28)),
          ),
        ],
      ),
    );
  }
}

class ThinkerRailTile extends StatelessWidget {
  const ThinkerRailTile({super.key, required this.thinker, this.trailing});

  final MindProfile thinker;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ThinkerAvatar(name: thinker.name, size: 44, color: thinker.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(thinker.name,
                  style: bodyStyle(
                      fontWeight: FontWeight.w800, color: AgoraColors.ink)),
              const SizedBox(height: 2),
              Text(
                thinker.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(
                    fontSize: 12.5, color: AgoraColors.inkSoft, height: 1.2),
              ),
            ],
          ),
        ),
        trailing ??
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: AgoraColors.inkSoft),
      ],
    );
  }
}

class TagRow extends StatelessWidget {
  const TagRow({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags
          .map((tag) => AgoraChip(
              label: tag,
              backgroundColor: AgoraColors.canvas,
              foregroundColor: AgoraColors.inkSoft))
          .toList(),
    );
  }
}
