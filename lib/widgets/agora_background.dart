import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

class AgoraBackground extends StatelessWidget {
  const AgoraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFBF5EA), AgoraColors.canvas],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _StagePainter())),
        child,
      ],
    );
  }
}

class _StagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _paintTopGlow(canvas, size);
    _paintMountains(canvas, size);
    _paintArch(canvas, size);
  }

  void _paintTopGlow(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBE8C9).withOpacity(0.85),
          const Color(0x00FBE8C9),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, -120),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.5, -120), size.width * 0.55, paint);
  }

  void _paintMountains(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final y1 = h * 0.72;
    final y2 = h * 0.80;
    final y3 = h * 0.88;
    final colors = [
      const Color(0xFFD9CCAA).withOpacity(0.72),
      const Color(0xFFC8B98E).withOpacity(0.48),
      const Color(0xFFC9B884).withOpacity(0.38),
    ];
    final ys = [y1, y2, y3];
    for (var i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(0, ys[i])
        ..cubicTo(w * 0.12, ys[i] - 45, w * 0.22, ys[i] + 20, w * 0.34, ys[i] - 18)
        ..cubicTo(w * 0.46, ys[i] - 58, w * 0.58, ys[i] + 28, w * 0.72, ys[i] - 8)
        ..cubicTo(w * 0.84, ys[i] - 42, w * 0.92, ys[i] + 16, w, ys[i] - 18)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
  }

  void _paintArch(Canvas canvas, Size size) {
    final baseX = size.width < 700 ? -20.0 : size.width * 0.075;
    final baseY = size.height + 18;
    final rect = Rect.fromCircle(
      center: Offset(baseX + 130, baseY - 92),
      radius: 120,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE7B4).withOpacity(0.85),
            const Color(0x00F4D78A),
          ],
        ).createShader(rect),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFC8B689).withOpacity(0.85);
    final left = baseX + 70;
    final top = baseY - 250;
    final right = baseX + 190;
    final bottom = baseY - 12;
    final path = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + 80)
      ..arcToPoint(Offset(right, top + 80), radius: const Radius.circular(60))
      ..lineTo(right, bottom);
    canvas.drawPath(path, stroke);

    final sparkle = Path()
      ..moveTo(baseX + 130, baseY - 158)
      ..lineTo(baseX + 134, baseY - 148)
      ..lineTo(baseX + 144, baseY - 144)
      ..lineTo(baseX + 134, baseY - 140)
      ..lineTo(baseX + 130, baseY - 130)
      ..lineTo(baseX + 126, baseY - 140)
      ..lineTo(baseX + 116, baseY - 144)
      ..lineTo(baseX + 126, baseY - 148)
      ..close();
    canvas.drawPath(sparkle, Paint()..color = const Color(0xFFF2C66A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
