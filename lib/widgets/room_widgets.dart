import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/models.dart';
import '../theme/agora_theme.dart';
import 'avatar.dart';
import 'chip.dart';
import 'soft_card.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.avatarColor = AgoraColors.accent,
  });

  final AgoraMessage message;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor =
        isUser ? AgoraColors.ink : Colors.white.withOpacity(0.96);
    final textColor = isUser ? Colors.white : AgoraColors.ink2;
    final metaColor = isUser ? Colors.white.withOpacity(0.86) : AgoraColors.ink;
    final time = DateFormat('h:mm a').format(message.createdAt);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ThinkerAvatar(
                name: message.speakerName,
                size: 40,
                color: avatarColor,
                dark: isUser,
                showInitial: isUser,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isUser ? AgoraColors.ink : AgoraColors.hair),
                  boxShadow: AgoraShadows.card,
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              message.speakerName,
                              overflow: TextOverflow.ellipsis,
                              style: bodyStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: metaColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.white.withOpacity(0.12)
                                  : AgoraColors.canvas,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              message.role,
                              style: bodyStyle(
                                fontSize: 11,
                                color: isUser
                                    ? Colors.white.withOpacity(0.84)
                                    : AgoraColors.inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            time,
                            style: bodyStyle(
                              fontSize: 11,
                              color: isUser
                                  ? Colors.white.withOpacity(0.56)
                                  : AgoraColors.mute,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        message.text,
                        style: bodyStyle(
                            fontSize: 15, height: 1.55, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaCard extends StatelessWidget {
  const AgendaCard({
    super.key,
    required this.item,
    required this.index,
    required this.active,
  });

  final AgendaItem item;
  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.66),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: active
                ? AgoraColors.accent.withOpacity(0.52)
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: bodyStyle(
                        fontWeight: FontWeight.w800,
                        color: AgoraColors.ink,
                        fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(
                  item.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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

class RoomMetricCard extends StatelessWidget {
  const RoomMetricCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: bodyStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AgoraColors.mute,
            ).copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ProgressPill extends StatelessWidget {
  const ProgressPill({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 9,
        color: const Color(0xFFEFE7D7),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                    colors: [AgoraColors.violet, AgoraColors.accent]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RoomMode value;
  final ValueChanged<RoomMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AgoraColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AgoraColors.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: RoomMode.values.map((mode) {
          final selected = value == mode;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected ? AgoraShadows.card : null,
              ),
              child: Text(
                mode.shortLabel,
                style: bodyStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? AgoraColors.ink : AgoraColors.inkSoft,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MemorySummaryCard extends StatelessWidget {
  const MemorySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white.withOpacity(0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgoraChip(
            label: 'Memory · Draft',
            icon: Icons.auto_awesome_rounded,
            backgroundColor: AgoraColors.lilac,
            foregroundColor: AgoraColors.violet,
            borderColor: Color(0xFFE1D8F4),
          ),
          const SizedBox(height: 12),
          Text(
            'AI Social MVP Hypothesis',
            style: displayStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'First validate whether the same question, reframed by different minds, leads the user to act. The public feed should carry high-quality summaries instead of becoming another echo chamber.',
            style: bodyStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AgoraChip(
                  label: '#thinking-room',
                  backgroundColor: AgoraColors.sky,
                  foregroundColor: Color(0xFF264FB1),
                  borderColor: Color(0xFFCCDDF3)),
              AgoraChip(
                  label: '#anti-echo',
                  backgroundColor: AgoraColors.lilac,
                  foregroundColor: Color(0xFF5847B1),
                  borderColor: Color(0xFFE1D8F4)),
              AgoraChip(
                  label: '#mvp',
                  backgroundColor: AgoraColors.canvas,
                  foregroundColor: AgoraColors.inkSoft),
            ],
          ),
        ],
      ),
    );
  }
}
