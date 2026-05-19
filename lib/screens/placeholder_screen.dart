import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';
import '../widgets/logo.dart';
import '../widgets/soft_card.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SoftCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AgoraLogo(iconSize: 54, textSize: 26),
                const SizedBox(height: 28),
                Icon(icon, size: 42, color: AgoraColors.accent),
                const SizedBox(height: 14),
                Text(title, style: displayStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: bodyStyle(fontSize: 15, color: AgoraColors.inkSoft, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
