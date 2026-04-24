import 'dart:math' as math;
import 'package:flutter/material.dart';

class WorldEngineBackground extends StatefulWidget {
  const WorldEngineBackground({super.key});

  @override
  State<WorldEngineBackground> createState() => _WorldEngineBackgroundState();
}

class _WorldEngineBackgroundState extends State<WorldEngineBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WorldBackgroundPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WorldBackgroundPainter extends CustomPainter {
  final double animationValue;
  _WorldBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw rotating grid lines
    for (var i = 0; i < 12; i++) {
      final angle = (i * 30 * math.pi / 180) + (animationValue * 2 * math.pi * 0.1);
      final x = centerX + math.cos(angle) * size.width;
      final y = centerY + math.sin(angle) * size.height;
      canvas.drawLine(Offset(centerX, centerY), Offset(x, y), paint);
    }

    // Draw pulsing circles
    for (var i = 1; i <= 3; i++) {
      final pulse = (animationValue + i / 3) % 1.0;
      final radius = pulse * size.width * 0.8;
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        Paint()
          ..color = Colors.blueAccent.withValues(alpha: (1.0 - pulse) * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
