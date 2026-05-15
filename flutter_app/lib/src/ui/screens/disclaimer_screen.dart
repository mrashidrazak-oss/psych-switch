// Disclaimer screen — first-launch legal/safety gate.
//
// The user MUST tap "I am a healthcare professional" before any
// clinical content surface becomes accessible. RN parity: same three
// bullet points, same CTA copy, same persistence key (so a user who
// acknowledged on RN doesn't get re-prompted on Flutter).
//
// Polish layer beyond RN parity:
//   • Ambient radial gradient backdrop (matches home).
//   • Brand monogram + bullets stagger-fade-in via EntranceFade.
//   • Haptic confirm on the CTA so the commit feels weighty.
//   • Accessibility semantics — the bullet block reads as one phrase
//     to VoiceOver / TalkBack rather than fragments.
//   • Reduced-motion preference automatically disables the stagger.
//
// Wiring: main.dart routes to this screen when
// `disclaimerAcknowledgedProvider` resolves to false.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/providers/disclaimer_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Ambient backdrop — same family as the home screen.
          const Positioned.fill(child: _AmbientBackdrop()),
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
                    EntranceFade(
                      index: 4,
                      child: Text(
                        'By tapping above you confirm you understand '
                        'the limitations.',
                        style: ClinicalText.caption.copyWith(
                          color: ClinicalPalette.muted,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.7),
            radius: 1.2,
            colors: <Color>[
              ClinicalPalette.toneLavenderInk.withValues(alpha: 0.1),
              ClinicalPalette.toneMintInk.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}

/// Brand hero on the disclaimer gate. Same composition as the home
/// screen's mark — real X-mark logo with a dual-tone soft glow, plus
/// a confident 24-pt wordmark and a two-tone-dot tagline. Replaces
/// the prior "PS" gradient-tile placeholder for brand parity across
/// the two screens the clinician sees most.
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
            // ── Brand mark with dual-tone glow ──────────────────────
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: ClinicalPalette.toneLavenderInk.withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: -8,
                    offset: const Offset(-5, 6),
                  ),
                  BoxShadow(
                    color: ClinicalPalette.toneMintInk.withValues(alpha: 0.28),
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
            // ── Wordmark + tagline ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'PsychSwitch',
                    style: TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const Gap.v(ClinicalSpace.xs + 1),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: ClinicalPalette.toneLavenderInk,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap.h(3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: ClinicalPalette.toneMintInk,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap.h(ClinicalSpace.sm),
                      const Text(
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

class _BulletBlock extends StatelessWidget {
  const _BulletBlock();

  static const _bullets = <(String, String)>[
    (
      'For qualified clinicians',
      'Reference cross-titration schedules drawn from Maudsley 15th, '
          'BAP 2020, NICE, and the Malaysian CPGs.',
    ),
    (
      'Not a substitute for clinical judgment',
      'Final prescribing decisions always rest with the treating '
          'clinician — patient factors, comorbidities, and local '
          'guidance take precedence.',
    ),
    (
      'Cross-check primary sources',
      "Verify dosing against the original references and your patient's "
          'individual context before acting on any plan.',
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
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg,
        ClinicalSpace.md,
        ClinicalSpace.lg,
        ClinicalSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < _bullets.length; i++) ...<Widget>[
            _Bullet(title: _bullets[i].$1, body: _bullets[i].$2),
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $body',
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
                    title,
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const Gap.v(ClinicalSpace.xs),
                  Text(
                    body,
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
