// DDI warnings during the cross-taper overlap window.
//
// Pulled from psychswitch_engine/ddi.dart `checkPair(from, to)`. Renders
// one row per pattern hit, severity-sorted with the most serious at top.
//
// Visual language:
//   • Eyebrow row: shield glyph + "OVERLAP-WINDOW INTERACTIONS" in
//     warning tone — flags this as a safety-first surface.
//   • Each hit: surface card with a 4-px severity-tinted left stripe.
//   • Severity label + formatted mechanism (snake_case → spaces),
//     message body, optional mitigation line.
//
// Severity → tone mapping mirrors the RN component:
//   info     → accent
//   caution  → warning
//   warning  → warning
//   avoid    → danger

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/ddi.dart';

class DdiWarningsCard extends StatelessWidget {
  const DdiWarningsCard({required this.hits, super.key});

  final List<DdiHit> hits;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) return const SizedBox.shrink();

    // Severity-sorted, most severe first.
    final sorted = <DdiHit>[...hits]
      ..sort((a, b) => severityRank(b.severity) - severityRank(a.severity));

    return Semantics(
      header: true,
      label: '${sorted.length} overlap-window interaction'
          '${sorted.length == 1 ? '' : 's'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Eyebrow: shield glyph + label.
          const Row(
            children: <Widget>[
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: ClinicalPalette.warning,
              ),
              Gap.h(ClinicalSpace.xs + 2),
              Text(
                'OVERLAP-WINDOW INTERACTIONS',
                style: TextStyle(
                  color: ClinicalPalette.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.sm),
          for (var i = 0; i < sorted.length; i++) ...<Widget>[
            _DdiHitRow(hit: sorted[i]),
            if (i < sorted.length - 1) const Gap.v(ClinicalSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _DdiHitRow extends StatelessWidget {
  const _DdiHitRow({required this.hit});

  final DdiHit hit;

  static Color _toneFor(DdiSeverity s) {
    switch (s) {
      case DdiSeverity.info:
        return ClinicalPalette.accent;
      case DdiSeverity.caution:
      case DdiSeverity.warning:
        return ClinicalPalette.warning;
      case DdiSeverity.avoid:
        return ClinicalPalette.danger;
    }
  }

  static String _labelFor(DdiSeverity s) {
    switch (s) {
      case DdiSeverity.info:
        return 'Note';
      case DdiSeverity.caution:
        return 'Caution';
      case DdiSeverity.warning:
        return 'Warning';
      case DdiSeverity.avoid:
        return 'Avoid';
    }
  }

  static String _formatMechanism(DdiMechanism m) =>
      m.jsonValue.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(hit.severity);
    final mechanism = _formatMechanism(hit.mechanism);
    final label = _labelFor(hit.severity);

    return Semantics(
      container: true,
      label: '$label, $mechanism. ${hit.message}'
          '${hit.mitigation != null ? '. Mitigation: ${hit.mitigation}' : ''}',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ClinicalRadii.tile),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ClinicalPalette.surface,
              border: Border.all(color: ClinicalPalette.border),
              borderRadius: BorderRadius.circular(ClinicalRadii.tile),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Severity stripe.
                  Container(width: 4, color: tone),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ClinicalSpace.md,
                        ClinicalSpace.md - 2,
                        ClinicalSpace.md,
                        ClinicalSpace.md - 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Eyebrow: severity label · mechanism.
                          Text(
                            '${label.toUpperCase()} · ${mechanism.toUpperCase()}',
                            style: TextStyle(
                              color: tone,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const Gap.v(ClinicalSpace.xs),
                          Text(
                            hit.message,
                            style: const TextStyle(
                              color: ClinicalPalette.text,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          if (hit.mitigation != null) ...<Widget>[
                            const Gap.v(ClinicalSpace.xs + 2),
                            RichText(
                              text: TextSpan(
                                style: ClinicalText.caption.copyWith(
                                  height: 1.5,
                                ),
                                children: <InlineSpan>[
                                  const TextSpan(
                                    text: 'Mitigation: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ClinicalPalette.mutedStrong,
                                    ),
                                  ),
                                  TextSpan(text: hit.mitigation),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
