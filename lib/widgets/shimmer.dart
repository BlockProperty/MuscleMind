import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1600),
    this.enabled = true,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          final dx = (t * 2.0) - 0.5;

          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment(-1.0 + dx, 0.0),
                end: Alignment(1.0 + dx, 0.0),
                colors: [
                  Colors.transparent,
                  LuxTheme.gold.withOpacity(0.08),
                  LuxTheme.gold.withOpacity(0.24),
                  LuxTheme.gold.withOpacity(0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                transform: const GradientRotation(math.pi / 12),
              ).createShader(rect);
            },
            child: child,
          );
        },
      ),
    );
  }
}
