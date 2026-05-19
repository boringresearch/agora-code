import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

class AgoraChip extends StatelessWidget {
  const AgoraChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = AgoraColors.canvas,
    this.foregroundColor = AgoraColors.inkSoft,
    this.borderColor = AgoraColors.hair,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: bodyStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
