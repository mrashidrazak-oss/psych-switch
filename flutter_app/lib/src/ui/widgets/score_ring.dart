// PsychSwitch Score ring — circular progress with band-tinted arc and
// the 0–100 number centred. Inspired by Stripe's confidence score.
//
// Pure presentation: takes a [PsychSwitchScore] and renders. The
// engine-side composition lives in lib/src/engine/psych_switch_score.dart.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    required this.score,
    super.key,
    this.size = 96,
    this.strokeWidth = 8,
  });

  final PsychSwitchScore score;
  final double size;
  final double strokeWidth;

  Color _bandColor() {
    switch (score.band) {
      case ScoreBand.excellent:
        return AppColors.to;
      case ScoreBand.good:
        return AppColors.accent;
      case ScoreBand.caution:
        return AppColors.warning;
      case ScoreBand.poor:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _bandColor();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: score.total / 100,
          color: color,
          strokeWidth: strokeWidth,
          trackColor: AppColors.border,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                score.total.toString(),
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bandLabel(score.band).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.shortestSide - strokeWidth) / 2;
    final c = Offset(size.width / 2, size.height / 2);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Start at 12 o'clock, sweep clockwise.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor;
}
