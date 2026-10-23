import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/lux_theme.dart';

class LuxBackground extends StatelessWidget {
  final Widget child;
  const LuxBackground({super.key, required this.child});

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
                colors: [
                  Color(0xFF020617),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: _DotTexture()),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    LuxTheme.gold.withOpacity(0.06),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  radius: 1.15,
                  center: const Alignment(0.0, -0.35),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DotTexture extends StatelessWidget {
  const _DotTexture();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _DotTexturePainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _DotTexturePainter extends CustomPainter {
  const _DotTexturePainter();

  static final List<_Dot> _dots = _generateDots();

  static List<_Dot> _generateDots() {
    final rng = Random(7);
    final List<_Dot> dots = [];

    const int count = 180;

    for (var i = 0; i < count; i++) {
      dots.add(
        _Dot(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: 0.5 + rng.nextDouble() * 1.2,
        ),
      );
    }

    return dots;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03);

    for (final dot in _dots) {
      final dx = dot.x * size.width;
      final dy = dot.y * size.height;
      canvas.drawCircle(Offset(dx, dy), dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Dot {
  final double x;
  final double y;
  final double radius;

  const _Dot({
    required this.x,
    required this.y,
    required this.radius,
  });
}