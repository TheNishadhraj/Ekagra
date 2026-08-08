import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/date_helpers.dart';

class FocusRing extends StatelessWidget {
  final double progress;
  final Duration remaining;
  final Color color;
  final double size;

  const FocusRing({
    super.key,
    required this.progress,
    required this.remaining,
    this.color = EkagraColors.focusActive,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FocusRingPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateHelpers.formatDuration(remaining),
                style: EkagraTypography.h1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: EkagraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress >= 1 ? 'Done' : 'remaining',
                style: EkagraTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FocusRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final bg = Paint()
      ..color = EkagraColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
