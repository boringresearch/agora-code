import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/agora_theme.dart';
import 'avatar.dart';
import 'logo.dart';

class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    const primary = [
      AppSection.home,
      AppSection.meetings,
      AppSection.think,
      AppSection.selfReflection,
      AppSection.saved,
    ];
    const secondary = [
      AppSection.quotes,
      AppSection.thinkers,
      AppSection.collections,
      AppSection.notifications,
      AppSection.messages,
    ];

    return SizedBox(
      width: 232,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 24),
                child: AgoraLogo(),
              ),
              ...primary.map((section) => _NavTile(
                    section: section,
                    selected: selected == section,
                    onTap: () => onSelected(section),
                  )),
              const SizedBox(height: 14),
              ...secondary.map((section) => _NavTile(
                    section: section,
                    selected: selected == section,
                    onTap: () => onSelected(section),
                    badge: switch (section) {
                      AppSection.thinkers => '12',
                      AppSection.collections => '4',
                      AppSection.notifications => '3',
                      AppSection.messages => '8',
                      _ => null,
                    },
                  )),
              const Spacer(),
              const _SidebarArch(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.86),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AgoraColors.hair),
                  boxShadow: AgoraShadows.card,
                ),
                child: Row(
                  children: [
                    const ThinkerAvatar(name: 'You', size: 38, dark: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You', style: bodyStyle(fontWeight: FontWeight.w800, color: AgoraColors.ink)),
                          Text('@you', style: bodyStyle(fontSize: 11, color: AgoraColors.mute)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AgoraColors.mute),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AgoraColors.canvas : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: selected ? Border.all(color: const Color(0xFFE6DCC4)) : null,
            ),
            child: Row(
              children: [
                Icon(section.icon, size: 20, color: selected ? AgoraColors.ink : AgoraColors.inkSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.label,
                    style: bodyStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? AgoraColors.ink : AgoraColors.inkSoft,
                    ),
                  ),
                ),
                if (badge != null)
                  Text(
                    badge!,
                    style: bodyStyle(fontSize: 11, color: AgoraColors.mute, fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      AppSection.home,
      AppSection.meetings,
      AppSection.think,
      AppSection.saved,
      AppSection.messages,
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: const Border(top: BorderSide(color: AgoraColors.hair)),
          boxShadow: [
            BoxShadow(
              color: AgoraColors.ink.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((section) {
            final isSelected = selected == section;
            return IconButton(
              onPressed: () => onSelected(section),
              icon: Icon(section.icon),
              color: isSelected ? AgoraColors.ink : AgoraColors.mute,
              tooltip: section.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SidebarArch extends StatelessWidget {
  const _SidebarArch();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 134,
      width: double.infinity,
      child: CustomPaint(painter: _SidebarArchPainter()),
    );
  }
}

class _SidebarArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowRect = Rect.fromCircle(center: Offset(size.width / 2, 84), radius: 78);
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE7B4).withOpacity(0.78),
          const Color(0x00FBE6B0),
        ]).createShader(glowRect),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0xFFC8B689);
    final path = Path()
      ..moveTo(size.width * 0.35, size.height - 4)
      ..lineTo(size.width * 0.35, 54)
      ..arcToPoint(Offset(size.width * 0.65, 54), radius: Radius.circular(size.width * 0.15))
      ..lineTo(size.width * 0.65, size.height - 4);
    canvas.drawPath(path, stroke);
    final sparkle = Paint()..color = const Color(0xFFF2C66A);
    canvas.drawCircle(Offset(size.width / 2, 72), 4, sparkle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
