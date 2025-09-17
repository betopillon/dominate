import 'dart:math';
import 'package:flutter/material.dart';

class SpaceBackground extends StatefulWidget {
  final Widget child;

  const SpaceBackground({super.key, required this.child});

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground> {
  final List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _generateStars();
  }

  void _generateStars() {
    final random = Random();
    for (int i = 0; i < 50; i++) {
      _stars.add(
        Star(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 1.5 + 0.5, // Much larger: 2-5 pixels
          speed: random.nextDouble() * 0.3 + 0.05,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Static stars
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: StaticStarsPainter(_stars),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double speed;

  Star({required this.x, required this.y, required this.size, required this.speed});
}

class StaticStarsPainter extends CustomPainter {
  final List<Star> stars;

  StaticStarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;

      // Draw glow effect for larger stars
      if (star.size > 1.0) {
        canvas.drawCircle(Offset(x, y), star.size * 1.5, glowPaint);
      }

      // Draw the main star
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(StaticStarsPainter oldDelegate) => false;
}
