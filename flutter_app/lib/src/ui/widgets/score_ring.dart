// PsychSwitch Score ring — circular progress with band-tinted arc and
// the 0–100 number centred. Inspired by Stripe's confidence score.
//
// Pure presentation: takes a [PsychSwitchScore] and renders. The
// engine-side composition lives in lib/src/engine/psych_switch_score.dart.
//
// The arc animates in on first paint (350ms) and re-animates whenever
// the score changes — rebuilding the ring with a new score smoothly
// re-tweens to the new value rather than snapping.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';

class ScoreRing extends StatefulWidget {
  const ScoreRing({
    required this.score,
    super.key,
    this.size = 96,
    this.strokeWidth = 8,
  });

  final PsychSwitchScore score;
  final double size;
  final double strokeWidth;

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late Animation<double> _progressAnim;
  late int _displayScore;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _displayScore = 0;
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.score.total / 100,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic))
      ..addListener(_onTick);
    _ctl.forward();
  }

  void _onTick() {
    setState(() {
      _displayScore = (_progressAnim.value * 100).round();
    });
  }

  @override
  void didUpdateWidget(covariant ScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score.total == widget.score.total) return;
    final from = _progressAnim.value;
    final to = widget.score.total / 100;
    _progressAnim.removeListener(_onTick);
    _progressAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic),
    )..addListener(_onTick);
    _ctl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _progressAnim.removeListener(_onTick);
    _ctl.dispose();
    super.dispose();
  }

  Color _bandColor() {
    switch (widget.score.band) {
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
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: _progressAnim.value,
          color: color,
          strokeWidth: widget.strokeWidth,
          trackColor: AppColors.border,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _displayScore.toString(),
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: widget.size * 0.32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bandLabel(widget.score.band).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
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

    // Subtle gradient sweep from band colour at start to a slightly
    // brighter shade at the leading edge — gives the arc presence
    // without becoming psychedelic.
    final rect = Rect.fromCircle(center: c, radius: r);
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: <Color>[
        color.withValues(alpha: 0.85),
        color,
      ],
      stops: const <double>[0, 1],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
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
