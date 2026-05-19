import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

class ThinkerAvatar extends StatelessWidget {
  const ThinkerAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.color = AgoraColors.accent,
    this.dark = false,
    this.showInitial = false,
  });

  final String name;
  final double size;
  final Color color;
  final bool dark;
  final bool showInitial;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AgoraColors.ink,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: showInitial
              ? Text(
                  _initial(name),
                  style: bodyStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.38,
                  ),
                )
              : Icon(Icons.person_outline_rounded, color: Colors.white, size: size * 0.48),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AgoraColors.hair),
      ),
      child: CustomPaint(
        painter: _AvatarPainter(color: color, seed: name.hashCode),
        child: showInitial
            ? Center(
                child: Text(
                  _initial(name),
                  style: bodyStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.34,
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }

  static String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final first = trimmed.substring(0, 1);
    return first.toUpperCase();
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({required this.color, required this.seed});

  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, size.width * 0.035)
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.72);
    final soft = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.07);

    final cx = size.width / 2;
    final headR = size.width * 0.18;
    final headCenter = Offset(cx, size.height * 0.37);
    canvas.drawCircle(headCenter, headR * 1.35, soft);
    canvas.drawCircle(headCenter, headR, stroke);

    final body = Rect.fromCenter(
      center: Offset(cx, size.height * 0.78),
      width: size.width * 0.52,
      height: size.height * 0.36,
    );
    canvas.drawArc(body, math.pi, math.pi, false, stroke);

    final hairOffset = (seed % 7 - 3) * size.width * 0.004;
    final hair = Path()
      ..moveTo(cx - headR * 0.9, headCenter.dy - headR * 0.55)
      ..quadraticBezierTo(cx + hairOffset, headCenter.dy - headR * 1.25, cx + headR * 0.95, headCenter.dy - headR * 0.5);
    canvas.drawPath(hair, stroke);

    final eyePaint = Paint()..color = color.withOpacity(0.78);
    canvas.drawCircle(Offset(cx - headR * 0.35, headCenter.dy - 1), size.width * 0.012, eyePaint);
    canvas.drawCircle(Offset(cx + headR * 0.35, headCenter.dy - 1), size.width * 0.012, eyePaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, headCenter.dy + headR * 0.22),
        width: headR * 0.72,
        height: headR * 0.42,
      ),
      0.15,
      math.pi - 0.3,
      false,
      stroke..strokeWidth = math.max(0.8, size.width * 0.02),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.seed != seed;
  }
}
