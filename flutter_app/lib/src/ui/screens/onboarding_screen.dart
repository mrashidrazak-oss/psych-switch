// Onboarding tour — three pages shown once after the first-launch
// disclaimer. Rewritten 2026-05-23 to share the ambient backdrop
// primitive with the disclaimer, add a subtle Breath pulse to each
// page's icon, and tighten the page-controller plumbing.
//
// Pages:
//   1. Plan a cross-titration   — what the engine does
//   2. Your patient, your taper — why patient context matters
//   3. Always the source        — provenance + citation depth
//
// Every page has a "Skip" link in the top-right that marks the tour
// complete without forcing the user through all three. Designed for
// returning users who tap "Restart tour" from About.
//
// Composition per page:
//   • Icon — tone-tinted, dual-tone-glow, Breath-wrapped for life
//   • Title — 30pt w800
//   • Body — 15pt regular, 1.6 line-height
//   • Icon → Title → Body cascade-in at 80ms stagger
//
// Chrome:
//   • Ambient backdrop (shared with Disclaimer)
//   • "Skip" text button top-right
//   • Page dots — active dot stretches to 24pt pill
//   • "Continue" / "Get started" pill bottom

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/providers/onboarding_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/ambient_backdrop.dart';
import 'package:psychswitch/src/ui/widgets/breath.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtl = PageController();
  int _page = 0;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.swap_horiz_rounded,
      tone: ClinicalPalette.accent,
      title: 'Plan a cross-titration',
      body:
          'PsychSwitch carries reviewed cross-taper rules from Maudsley '
          '15th, BAP 2020, NICE, and the Malaysian CPGs. Pick a '
          'from-drug, a to-drug, and the doses — the engine returns a '
          'day-by-day schedule with safety flags, '
          'monitoring touchpoints, and an overlap-intensity score.',
    ),
    _OnboardingPage(
      icon: Icons.person_outline_rounded,
      tone: ClinicalPalette.toneMintInk,
      title: 'Your patient, your taper',
      body:
          'Set patient context once — age, sex, pregnancy, '
          'hepatic/renal state, cardiac history — and every plan '
          'adapts. Switch speed (Faster · Standard · Slower), Day-1 '
          'softening (Maudsley halve-and-add), and dose adaptation are '
          'all one tap away on the result screen.',
    ),
    _OnboardingPage(
      icon: Icons.menu_book_rounded,
      tone: ClinicalPalette.toneLavenderInk,
      title: 'Always the source',
      body:
          'Every rule traces back to a citable paragraph. Tap any '
          'citation to see the source explained in plain English plus '
          'how PsychSwitch uses it. The rule provenance card on every '
          'plan names the reviewer and the last-reviewed date.',
    ),
  ];

  @override
  void dispose() {
    _pageCtl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    unawaited(hapticsConfirm());
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
  }

  Future<void> _skip() async {
    unawaited(hapticsTap());
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
  }

  void _next() {
    unawaited(hapticsTap());
    if (_page == _pages.length - 1) {
      unawaited(_finish());
      return;
    }
    _pageCtl.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: ClinicalPalette.bg,
      body: Stack(
        children: <Widget>[
          // Slightly different center than Disclaimer — onboarding
          // wash anchored further left so the gradient doesn't bleed
          // into the page-icon area on small phones.
          const Positioned.fill(
            child: AmbientBackdrop(center: Alignment(-0.3, -0.7)),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                _SkipBar(onSkip: _skip),
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnboardingPageView(
                      page: _pages[i],
                    ),
                  ),
                ),
                _PageDots(count: _pages.length, active: _page),
                const Gap.v(ClinicalSpace.lg),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ClinicalSpace.xl,
                    0,
                    ClinicalSpace.xl,
                    ClinicalSpace.xl,
                  ),
                  child: _ContinueButton(
                    label: isLast ? 'Get started' : 'Continue',
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page data ───────────────────────────────────────────────────────

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String body;
}

// ── Skip bar ────────────────────────────────────────────────────────

class _SkipBar extends StatelessWidget {
  const _SkipBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClinicalSpace.lg,
          ClinicalSpace.sm,
          ClinicalSpace.lg,
          0,
        ),
        child: TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: ClinicalPalette.muted,
          ),
          child: const Text(
            'Skip',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page view ──────────────────────────────────────────────────────

/// One onboarding page — icon (with Breath + glow), title, body.
/// Three EntranceFades with 80ms stagger reinforce the read order.
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.xl,
        ClinicalSpace.xl,
        ClinicalSpace.xl,
        ClinicalSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(flex: 2),
          EntranceFade(
            stagger: const Duration(milliseconds: 80),
            child: Breath(child: _PageIcon(page: page)),
          ),
          const Gap.v(ClinicalSpace.xl),
          EntranceFade(
            index: 1,
            stagger: const Duration(milliseconds: 80),
            child: Text(
              page.title,
              style: const TextStyle(
                color: ClinicalPalette.text,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
          ),
          const Gap.v(ClinicalSpace.md + 2),
          EntranceFade(
            index: 2,
            stagger: const Duration(milliseconds: 80),
            child: Text(
              page.body,
              style: const TextStyle(
                color: ClinicalPalette.mutedStrong,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// 86pt tone-tinted icon with a single-direction dual-tone-style glow.
/// Same composition family as the disclaimer's brand mark — calmer
/// because it changes per page.
class _PageIcon extends StatelessWidget {
  const _PageIcon({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: page.tone.withValues(alpha: 0.32),
            blurRadius: 36,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: page.tone.withValues(alpha: 0.12),
          border: Border.all(
            color: page.tone.withValues(alpha: 0.36),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(ClinicalRadii.card),
        ),
        child: Center(
          child: Icon(page.icon, size: 38, color: page.tone),
        ),
      ),
    );
  }
}

// ── Page dots ──────────────────────────────────────────────────────

/// Active-page indicator: 7pt dots with the current one stretched to
/// a 24pt pill via AnimatedContainer (240ms easeOutCubic).
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: i == active ? 24 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active
                  ? ClinicalPalette.accent
                  : ClinicalPalette.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(ClinicalRadii.pill),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Continue button ────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ClinicalRadii.card),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: ClinicalPalette.accent.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: ClinicalPalette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClinicalRadii.card),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const Gap.h(ClinicalSpace.sm + 2),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
