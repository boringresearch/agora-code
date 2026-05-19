import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

class AgoraLogo extends StatelessWidget {
  const AgoraLogo({
    super.key,
    this.showText = true,
    this.iconSize = 38,
    this.textSize = 20,
  });

  final bool showText;
  final double iconSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize * 0.9,
          height: iconSize,
          child: CustomPaint(painter: _LogoPainter()),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'Mind Agora',
            style: displayStyle(fontSize: textSize, fontWeight: FontWeight.w800, height: 1),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AgoraColors.ink, AgoraColors.accent],
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(Offset.zero & size);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF2C66A);

    final left = size.width * 0.15;
    final right = size.width * 0.85;
    final top = size.height * 0.08;
    final bottom = size.height * 0.94;
    final archTop = size.height * 0.34;
    final path = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, archTop)
      ..arcToPoint(
        Offset(right, archTop),
        radius: Radius.circular(size.width * 0.35),
      )
      ..lineTo(right, bottom);
    canvas.drawPath(path, stroke);
    canvas.drawLine(Offset(size.width * 0.5, top), Offset(size.width * 0.5, bottom * 0.94), gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
