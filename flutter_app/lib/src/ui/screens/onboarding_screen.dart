// Onboarding tour — three pages shown once after the first-launch
// disclaimer. Sets expectations for what the app does, what context
// to set, and how to read the source provenance.
//
// Pages:
//   1. Plan a cross-titration  — what the engine does
//   2. Your patient, your taper — why patient context matters
//   3. Always the source         — provenance + citation depth
//
// Every page has a "Skip" link in the top-right that marks the tour
// complete without forcing the user through all three. Designed for
// returning users who tap "Restart tour" from About.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/providers/onboarding_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

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
      tone: AppColors.accent,
      title: 'Plan a cross-titration',
      body:
          'PsychSwitch carries reviewed cross-taper rules from Maudsley 15, '
          'BAP 2020, NICE, and the Malaysian CPGs. Pick a from-drug, a '
          'to-drug, and the doses — the engine returns a day-by-day '
          'schedule with safety flags, monitoring touchpoints, and an '
          'overlap-intensity score.',
    ),
    _OnboardingPage(
      icon: Icons.person_outline_rounded,
      tone: AppColors.to,
      title: 'Your patient, your taper',
      body:
          'Set patient context once — age, sex, pregnancy, hepatic/renal '
          'state, cardiac history — and every plan adapts. Switch speed '
          '(Faster · Standard · Slower), Day-1 softening (Maudsley '
          'halve-and-add), and dose adaptation are all one tap away on the '
          'result screen.',
    ),
    _OnboardingPage(
      icon: Icons.menu_book_rounded,
      tone: AppColors.from,
      title: 'Always the source',
      body:
          'Every rule traces back to a citable paragraph. Tap any citation '
          'to see the source explained in plain English plus how '
          'PsychSwitch uses it. The rule provenance card on every plan '
          'names the reviewer and the last-reviewed date.',
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          // Ambient backdrop — same family as home / disclaimer.
          const Positioned.fill(child: _AmbientBackdrop()),
          SafeArea(
            child: Column(
              children: <Widget>[
                // ── Top bar — Skip link ─────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.sm,
                      AppSpace.lg,
                      0,
                    ),
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
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
                ),
                // ── Pages ───────────────────────────────────────────
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
                // ── Dots ────────────────────────────────────────────
                _PageDots(count: _pages.length, active: _page),
                const Gap.v(AppSpace.lg),
                // ── Next / Get started CTA ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl,
                    0,
                    AppSpace.xl,
                    AppSpace.xl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.28),
                            blurRadius: 22,
                            spreadRadius: -6,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _page == _pages.length - 1
                                  ? 'Get started'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const Gap.h(AppSpace.sm + 2),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(flex: 2),
          // Big rounded-square icon with tone-tinted background + soft
          // dual-tone glow matching the brand mark on home / disclaimer.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xl),
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
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Center(
                child: Icon(
                  page.icon,
                  size: 38,
                  color: page.tone,
                ),
              ),
            ),
          ),
          const Gap.v(AppSpace.xl),
          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const Gap.v(AppSpace.md + 2),
          Text(
            page.body,
            style: const TextStyle(
              color: AppColors.mutedStrong,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

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
                  ? AppColors.accent
                  : AppColors.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ],
      ],
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.7),
            radius: 1.2,
            colors: <Color>[
              AppColors.from.withValues(alpha: 0.1),
              AppColors.to.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
