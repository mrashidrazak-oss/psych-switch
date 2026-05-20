// Rating-scales index — the launchpad for in-app symptom scoring.
//
// Renders the curated set of public-domain scales from
// `psychswitch_engine/scales.dart` as tone-tinted squircle tiles. Tap
// a tile to launch the runner.
//
// Scales shipped on first release:
//   • PHQ-9   — depression screening
//   • GAD-7   — anxiety screening
//   • HAM-D-17 — clinician-rated depression
//   • AIMS     — tardive-dyskinesia surveillance
//
// All public-domain, no licensing entanglements. PANSS / YMRS / MoCA
// are intentionally excluded until we have explicit licences.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/scales.dart';

class ScalesScreen extends StatelessWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating scales'),
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
            for (var i = 0; i < kClinicalScales.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: ClinicalSpace.md),
              _ScaleTile(scale: kClinicalScales[i], index: i),
            ],
            const SizedBox(height: ClinicalSpace.lg),
            const _FooterNote(),
          ],
        ),
      ),
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSky,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Symptom scoring',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Score in seconds, document in plain numbers',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneSkyInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Tap a scale to run it. Items have anchor descriptors; the '
            'total updates live and lands on a severity band you can '
            'paste straight into your notes.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSkyInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scale tile ──────────────────────────────────────────────────────

class _ScaleTile extends StatelessWidget {
  const _ScaleTile({required this.scale, required this.index});

  final ClinicalScale scale;
  final int index;

  /// Rotate tone family per row so the grid reads as four distinct
  /// scales rather than four identical white cards.
  static const _tones = <({Color tone, Color ink})>[
    (tone: ClinicalPalette.toneLavender, ink: ClinicalPalette.toneLavenderInk),
    (tone: ClinicalPalette.tonePeach, ink: ClinicalPalette.tonePeachInk),
    (tone: ClinicalPalette.toneMint, ink: ClinicalPalette.toneMintInk),
    (tone: ClinicalPalette.toneRose, ink: ClinicalPalette.toneRoseInk),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _tones[index % _tones.length];
    return SquircleCard(
      tone: palette.tone,
      radius: ClinicalRadii.tile + 4,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      onTap: () => context.pushNamed(
        Routes.scaleRunner,
        pathParameters: <String, String>{'id': scale.id},
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
            child: Icon(
              _iconFor(scale.id),
              size: 20,
              color: palette.ink,
            ),
          ),
          const SizedBox(width: ClinicalSpace.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      scale.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: ClinicalSpace.sm),
                    TonePill(
                      label: '0–${scale.maxScore}',
                      tone: Colors.white.withValues(alpha: 0.7),
                      ink: palette.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  scale.tagline,
                  style: ClinicalText.caption.copyWith(
                    color: palette.ink.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: palette.ink.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'phq9':
        return Icons.psychology_outlined;
      case 'gad7':
        return Icons.air;
      case 'hamd17':
        return Icons.medical_information_outlined;
      case 'aims':
        return Icons.accessibility_new;
      default:
        return Icons.assignment_outlined;
    }
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.privacy_tip_outlined,
            size: 16,
            color: ClinicalPalette.mutedStrong,
          ),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Scores stay on this device. Public-domain instruments '
              'only (PHQ/GAD via Pfizer; HAM-D, AIMS via NIMH). '
              'Licensed scales — PANSS, YMRS, MoCA — are intentionally '
              'omitted to avoid licensing entanglements.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
