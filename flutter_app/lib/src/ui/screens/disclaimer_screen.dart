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
                horizontal: AppSpace.xl,
                vertical: AppSpace.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      AppSpace.xxl * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const EntranceFade(child: _BrandHero()),
                    const Gap.v(AppSpace.xl),
                    const EntranceFade(index: 1, child: _Headline()),
                    const Gap.v(AppSpace.lg),
                    const EntranceFade(index: 2, child: _BulletBlock()),
                    const Gap.v(AppSpace.lg),
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
                    const Gap.v(AppSpace.md),
                    EntranceFade(
                      index: 4,
                      child: Text(
                        'By tapping above you confirm you understand '
                        'the limitations.',
                        style: AppTextSizes.micro.copyWith(
                          color: AppColors.muted,
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

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'PsychSwitch. Reviewed cross-titration.',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[AppColors.from, AppColors.to],
                ),
                borderRadius: BorderRadius.circular(AppRadii.md),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'PS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const Gap.h(AppSpace.md),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'PsychSwitch',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Gap.v(2),
                Text(
                  'REVIEWED CROSS-TITRATION',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
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
            color: AppColors.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.6,
          ),
        ),
        Text(
          'not medical advice.',
          style: TextStyle(
            color: AppColors.muted,
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < _bullets.length; i++) ...<Widget>[
            _Bullet(title: _bullets[i].$1, body: _bullets[i].$2),
            if (i < _bullets.length - 1) ...<Widget>[
              const Gap.v(AppSpace.md),
              const Divider(height: 1),
              const Gap.v(AppSpace.md),
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
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const Gap.h(AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const Gap.v(AppSpace.xs),
                  Text(
                    body,
                    style: AppTextSizes.caption.copyWith(height: 1.5),
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
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
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
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
          ),
        ),
      ),
    );
  }
}
