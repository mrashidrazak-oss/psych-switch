// Disclaimer screen — first-launch legal/safety gate. Rewritten
// 2026-05-23 to share the ambient backdrop with onboarding, add a
// subtle "alive" pulse to the brand mark, and warm the final
// microcopy with a privacy-respecting note.
//
// The user MUST tap "I am a healthcare professional" before any
// clinical content surface becomes accessible. Acknowledgement is
// persisted via `disclaimerAcknowledgedProvider`; this screen never
// re-shows for the same install (or for a returning RN user — same
// persistence key).
//
// Composition (top → bottom):
//   1. _BrandHero        Icon + wordmark + two-tone-dot tagline.
//                        Wrapped in Breath for a 0.5%/4s scale loop
//                        so the brand mark reads as "alive" without
//                        registering as motion.
//   2. _Headline         "Decision support, / not medical advice."
//   3. _BulletBlock      Three bullets in a card; named _Bullet
//                        records keep the data declarative.
//   4. _AcknowledgeButton  Primary accent pill — "I am a healthcare
//                          professional."
//   5. _BelowCta         Two-line microcopy: warmth + privacy.
//
// Test contract preserved (test/ui/disclaimer_screen_test.dart):
//   • 'PsychSwitch' wordmark
//   • 'Reviewed cross-titration' tagline
//   • 'Decision support,' + 'not medical advice.' headline
//   • 'Grounded in primary sources' bullet 1
//   • 'Not a substitute for clinical judgement' bullet 2
//   • 'Cross-check primary sources' bullet 3
//   • 'I am a healthcare professional' CTA
//   • Tap acknowledges + flips the persisted flag.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/providers/disclaimer_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/ambient_backdrop.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AmbientBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.xl,
                vertical: ClinicalSpace.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      ClinicalSpace.xxl * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EntranceFade(child: _BrandHero()),
                    const Gap.v(ClinicalSpace.xl),
                    const EntranceFade(index: 1, child: _Headline()),
                    const Gap.v(ClinicalSpace.lg),
                    const EntranceFade(index: 2, child: _BulletBlock()),
                    const Gap.v(ClinicalSpace.lg),
                    EntranceFade(
                      index: 3,
                      child: _AcknowledgeButton(
                        onPressed: () async {
                          unawaited(hapticsConfirm());
                          await ref
                              .read(disclaimerAcknowledgedProvider.notifier)
                              .acknowledge();
                        },
                      ),
                    ),
                    const Gap.v(ClinicalSpace.md),
                    const EntranceFade(index: 4, child: _BelowCta()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand hero ──────────────────────────────────────────────────────

/// Real icon + wordmark + two-tone-dot tagline. The dual-tone glow on
/// the mark + the Breath wrapper above this widget combine to make the
/// brand feel present without ever calling attention to itself.
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  static const double _markSize = 54;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'PsychSwitch. Reviewed cross-titration.',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: ClinicalPalette.toneLavenderInk
                        .withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: -8,
                    offset: const Offset(-5, 6),
                  ),
                  BoxShadow(
                    color: ClinicalPalette.toneMintInk
                        .withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: -8,
                    offset: const Offset(5, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                child: Image.asset(
                  'assets/icon.png',
                  width: _markSize,
                  height: _markSize,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const Gap.h(ClinicalSpace.md + 2),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'PsychSwitch',
                    style: TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  Gap.v(ClinicalSpace.xs + 1),
                  _Tagline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-dot tagline ("● ● Reviewed cross-titration"). Dots picked up
/// from the brand mark's gradient anchors (lavender + mint).
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _Dot(color: ClinicalPalette.toneLavenderInk),
        Gap.h(3),
        _Dot(color: ClinicalPalette.toneMintInk),
        Gap.h(ClinicalSpace.sm),
        Text(
          'Reviewed cross-titration',
          style: TextStyle(
            color: ClinicalPalette.mutedStrong,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Headline ────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Decision support,',
          style: TextStyle(
            color: ClinicalPalette.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.6,
          ),
        ),
        Text(
          'not medical advice.',
          style: TextStyle(
            color: ClinicalPalette.muted,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

// ── Bullet block ────────────────────────────────────────────────────

/// Three bullets in a hairline-bordered card. Named _Bullet records
/// instead of inline tuples — extends naturally if a fourth bullet
/// ever lands.
class _BulletBlock extends StatelessWidget {
  const _BulletBlock();

  static const _bullets = <_Bullet>[
    _Bullet(
      title: 'Grounded in primary sources',
      body: 'Cross-titration schedules drawn from Maudsley 15th, BAP '
          '2020, NICE, and the Malaysian CPGs — every rule cites where '
          'it came from.',
    ),
    _Bullet(
      title: 'Not a substitute for clinical judgement',
      body: 'Final prescribing decisions always rest with the treating '
          'clinician — patient factors, comorbidities, and local '
          'guidance take precedence.',
    ),
    _Bullet(
      title: 'Cross-check primary sources',
      body: 'Verify dosing against the original references and your '
          "patient's individual context before acting on any plan.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: ClinicalPalette.border),
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.lg,
        vertical: ClinicalSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < _bullets.length; i++) ...<Widget>[
            _BulletRow(bullet: _bullets[i]),
            if (i < _bullets.length - 1) ...<Widget>[
              const Gap.v(ClinicalSpace.md),
              const Divider(height: 1),
              const Gap.v(ClinicalSpace.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _Bullet {
  const _Bullet({required this.title, required this.body});

  final String title;
  final String body;
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.bullet});

  final _Bullet bullet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${bullet.title}. ${bullet.body}',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                color: ClinicalPalette.accent,
                shape: BoxShape.circle,
              ),
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    bullet.title,
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const Gap.v(ClinicalSpace.xs),
                  Text(
                    bullet.body,
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Acknowledge button ─────────────────────────────────────────────

class _AcknowledgeButton extends StatelessWidget {
  const _AcknowledgeButton({required this.onPressed});

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
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('I am a healthcare professional'),
          style: FilledButton.styleFrom(
            backgroundColor: ClinicalPalette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: ClinicalSpace.lg),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClinicalRadii.card),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Below CTA microcopy ─────────────────────────────────────────────

/// Two-line microcopy under the CTA: the acknowledgement reminder plus
/// a warm privacy reassurance. Previously a single legalistic line;
/// the second line now earns space by telling the clinician the
/// trust-signal that matters most ("your data stays on this device").
class _BelowCta extends StatelessWidget {
  const _BelowCta();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'By tapping above you confirm you understand the limitations.',
          style: ClinicalText.caption.copyWith(
            color: ClinicalPalette.muted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap.v(ClinicalSpace.xs),
        Text(
          'Your data stays on this device.',
          style: ClinicalText.caption.copyWith(
            color: ClinicalPalette.muted.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
