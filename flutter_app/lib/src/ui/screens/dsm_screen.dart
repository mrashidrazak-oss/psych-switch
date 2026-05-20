// DSM-5-TR Quick Criteria — bedside checkbox aid for the most-common
// psychiatric diagnoses.
//
// NOT a diagnostic instrument — surfaces the structure + tally so the
// clinician can step through criterion sets at the bedside. Final
// judgement always rests with the assessor (and the citations footer
// reminds them).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/dsm.dart';

class DsmScreen extends StatelessWidget {
  const DsmScreen({super.key});

  static const _tones = <({Color tone, Color ink})>[
    (tone: ClinicalPalette.toneLavender, ink: ClinicalPalette.toneLavenderInk),
    (tone: ClinicalPalette.tonePeach, ink: ClinicalPalette.tonePeachInk),
    (tone: ClinicalPalette.toneMint, ink: ClinicalPalette.toneMintInk),
    (tone: ClinicalPalette.toneRose, ink: ClinicalPalette.toneRoseInk),
    (tone: ClinicalPalette.toneSky, ink: ClinicalPalette.toneSkyInk),
    (tone: ClinicalPalette.toneSand, ink: ClinicalPalette.toneSandInk),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSM-5-TR criteria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg + 4,
            ClinicalSpace.lg,
            ClinicalSpace.lg + 4,
            ClinicalSpace.xl,
          ),
          children: <Widget>[
            const _Hero(),
            const SizedBox(height: ClinicalSpace.lg),
            for (var i = 0; i < kDsmDisorders.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: ClinicalSpace.md),
              _DisorderTile(
                disorder: kDsmDisorders[i],
                palette: _tones[i % _tones.length],
              ),
            ],
            const SizedBox(height: ClinicalSpace.lg),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneLavender,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Bedside criteria',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Tick the criterion. We tally the rule.',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneLavenderInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Structured DSM-5-TR criterion sets for the eight '
            'commonest psychiatric presentations. Tap a disorder to '
            'step through the criteria with live met / not-met '
            'tallies. Documentation-grade, not diagnostic-grade.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneLavenderInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisorderTile extends StatelessWidget {
  const _DisorderTile({required this.disorder, required this.palette});

  final DsmDisorder disorder;
  final ({Color tone, Color ink}) palette;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: palette.tone,
      radius: ClinicalRadii.tile + 4,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      onTap: () => context.pushNamed(
        Routes.dsmRunner,
        pathParameters: <String, String>{'id': disorder.id},
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(ClinicalRadii.chip),
            ),
            child: Text(
              disorder.code,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: palette.ink,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: ClinicalSpace.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  disorder.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disorder.tagline,
                  style: ClinicalText.caption.copyWith(
                    color: palette.ink.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: palette.ink.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.shield_outlined,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Paraphrased from DSM-5-TR (APA, 2022) for fair-use '
              'clinical summary. Not a diagnostic instrument — final '
              'judgement, exclusionary rule-outs, and functional '
              'impairment review rest with the clinician.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
