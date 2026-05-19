import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 18,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AgoraColors.paper.withOpacity(0.90),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AgoraColors.hair.withOpacity(0.72)),
        boxShadow: shadow ? AgoraShadows.card : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: content,
    );
  }
}

class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AgoraColors.paper,
          shape: const CircleBorder(
            side: BorderSide(color: AgoraColors.hair),
          ),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            color: AgoraColors.inkSoft,
          ),
        ),
        if (badge)
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AgoraColors.accent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AgoraColors.cream, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
