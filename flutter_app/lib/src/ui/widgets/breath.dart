// Breath — a continuous, almost-imperceptible scale loop. Used for
// surfaces meant to feel "alive" without animating in a way the eye
// catches as motion. Default 0.5% scale, 4s period, eased.
//
// Used on Home's "Today's pearl" card so the wisdom-card holds the
// page subtly instead of sitting on it. Same dial Apple uses on
// Watch complications.
//
// Honours reduced-motion: when MediaQuery.disableAnimations is true,
// the child renders un-wrapped (no controller, no animation).

import 'package:flutter/material.dart';

class Breath extends StatefulWidget {
  const Breath({
    required this.child,
    super.key,
    this.amplitude = 0.005,
    this.period = const Duration(milliseconds: 4000),
  });

  final Widget child;

  /// Half-amplitude — child scales 1.0 → 1+amplitude → 1.0 each period.
  /// 0.005 = 0.5% which is the threshold of perception at typical
  /// viewing distance; the eye reads it as "alive" without registering
  /// as motion.
  final double amplitude;

  /// One full breath cycle (1.0 → peak → 1.0).
  final Duration period;

  @override
  State<Breath> createState() => _BreathState();
}

class _BreathState extends State<Breath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.period);
    _scale = Tween<double>(begin: 1, end: 1 + widget.amplitude).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _ctl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
