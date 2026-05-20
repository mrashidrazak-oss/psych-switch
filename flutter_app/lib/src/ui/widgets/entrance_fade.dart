// Entrance-fade — a tiny staggered-slide-up wrapper for hero
// elements. Used on Home and on big "you arrived" surfaces (Result
// hero, History list).
//
// Each child fades in (opacity 0 → 1) and slides up 8px. Staggered
// by [index] × 60ms so a 5-item column unfolds in ~360ms — felt as
// "arriving" rather than "loading."
//
// Honours system reduced-motion by skipping the animation entirely
// when MediaQuery.disableAnimations is set.

import 'dart:async';

import 'package:flutter/material.dart';

class EntranceFade extends StatefulWidget {
  const EntranceFade({
    required this.child,
    super.key,
    this.index = 0,
    this.duration = const Duration(milliseconds: 380),
    this.stagger = const Duration(milliseconds: 60),
    this.slidePx = 8,
  });

  final Widget child;

  /// Stagger position. 0 = first to enter, 1 = second, etc.
  final int index;
  final Duration duration;
  final Duration stagger;
  final double slidePx;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slidePx / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic));

    final delay = widget.stagger * widget.index;
    if (delay == Duration.zero) {
      _ctl.forward();
    } else {
      _startTimer = Timer(delay, () {
        if (!mounted) return;
        _ctl.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
