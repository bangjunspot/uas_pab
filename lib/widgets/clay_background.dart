import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/clay_colors.dart';

class ClayBackground extends StatefulWidget {
  final Widget child;
  const ClayBackground({super.key, required this.child});

  @override
  State<ClayBackground> createState() => _ClayBackgroundState();
}

class _ClayBackgroundState extends State<ClayBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
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
        final t = _controller.value;
        return Stack(
          children: [
            Positioned(
              top: 40 + (t * 20),
              left: 30 + (t * 10),
              child: _Blob(color: ClayColors.primary.withAlpha(61), size: 180),
            ),
            Positioned(
              bottom: 60 + (t * 15),
              right: 40 + (t * 12),
              child: _Blob(
                color: ClayColors.secondary.withAlpha(56),
                size: 200,
              ),
            ),
            Positioned(
              top: 220 - (t * 10),
              right: 120 - (t * 8),
              child: _Blob(color: ClayColors.warning.withAlpha(46), size: 140),
            ),
            child!,
          ],
        );
      },
      child: Container(color: ClayColors.canvas, child: widget.child),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
