// Press-scale — the subtle tactile feedback that makes a button feel
// like it's being touched.
//
// On press-down, the child scales 1.0 → [pressedScale] over ~80ms with
// an easeOut curve (the "depress" feels immediate). On release / cancel,
// it springs back to 1.0 over ~220ms with an easeOutBack curve that
// produces a soft overshoot — the "lift" feels lively.
//
// Composes with InkWell/InkResponse instead of replacing them — the
// Material ripple still fires, the scale runs on top. Wrap a child that
// already has its own onTap (a card, a button) and pass the same onTap
// through PressScale.onTap to get both behaviours without double-tap
// dispatch.
//
// Honours system reduced-motion: when MediaQuery.disableAnimations is
// true, the scale animation is skipped and the tap dispatches normally.

import 'package:flutter/material.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    super.key,
    this.onTap,
    this.pressedScale = 0.97,
    this.pressDuration = const Duration(milliseconds: 80),
    this.releaseDuration = const Duration(milliseconds: 220),
    this.enabled = true,
  });

  final Widget child;

  /// Optional tap callback. When set, PressScale absorbs the gesture
  /// and dispatches onTap on release (matching GestureDetector
  /// semantics — cancelled if the finger drags off the child).
  ///
  /// Leave null when the wrapped child has its own onTap (e.g. an
  /// InkWell) — PressScale will still respond to press-down/cancel via
  /// the gesture detector layered above it.
  final VoidCallback? onTap;

  /// Target scale at the bottom of the press. Default 0.97 matches the
  /// iOS button feel.
  final double pressedScale;
  final Duration pressDuration;
  final Duration releaseDuration;

  /// Hard switch — set false to disable the scale entirely (e.g. for
  /// disabled buttons).
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.releaseDuration,
      value: 0,
    );
    _scale = Tween<double>(begin: 1, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _ctl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    _ctl.forward();
  }

  void _release() {
    if (!widget.enabled) return;
    _ctl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      // No motion — just dispatch the tap and pass through.
      if (widget.onTap == null) return widget.child;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.child,
      );
    }
    return Listener(
      // Listener catches press-down even if a child gesture wins the
      // arena (InkWell, etc.) — the scale animates regardless.
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        // onTap fires only when the gesture wins (drag-off cancels).
        // When the child handles tap itself (InkWell), this stays null
        // and we don't double-dispatch.
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
