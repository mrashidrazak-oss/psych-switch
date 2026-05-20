// Errata screen — public audit trail of every clinical-content change.
// RN parity: `screens/ErrataScreen.tsx`.
//
// Search by rule id, drug name, or free text. Filter by severity.
// Each row expands to show before/after, rationale, reviewer,
// supporting citations.
//
// Visible to anyone — this is a *trust signal*. The whole point of an
// errata feed is that it's open and scrolls forever.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/errata.dart';

class ErrataScreen extends StatefulWidget {
  const ErrataScreen({super.key});

  @override
  State<ErrataScreen> createState() => _ErrataScreenState();
}

class _ErrataScreenState extends State<ErrataScreen> {
  final _searchCtl = TextEditingController();
  ErrataSeverity? _severityFilter; // null = all

  static const _severities = <(ErrataSeverity?, String)>[
    (null, 'All'),
    (ErrataSeverity.critical, 'Critical'),
    (ErrataSeverity.significant, 'Significant'),
    (ErrataSeverity.moderate, 'Moderate'),
    (ErrataSeverity.minor, 'Minor'),
  ];

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<ErrataEntry> _filtered() {
    final all = listErrata();
    var out = all;
    if (_severityFilter != null) {
      out = out.where((e) => e.severity == _severityFilter).toList();
    }
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.length >= 2) {
      out = out.where((e) {
        return e.scope.toLowerCase().contains(q) ||
            e.scopeLabel.toLowerCase().contains(q) ||
            e.summary.toLowerCase().contains(q) ||
            e.detail.toLowerCase().contains(q) ||
            e.rationale.toLowerCase().contains(q);
      }).toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Errata'),
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
            Text(
              '${errataCount()} corrections recorded since v0.1. Every '
              'accepted change is logged with a reviewer signature and '
              'citation. No edits, no quiet rewrites — append-only audit '
              'trail.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
            const Gap.v(ClinicalSpace.lg),

            // Search.
            TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search rule, drug, summary',
                prefixIcon: Icon(
                  Icons.search,
                  color: ClinicalPalette.muted,
                  size: 20,
                ),
              ),
              style: const TextStyle(color: ClinicalPalette.text, fontSize: 14),
            ),
            const Gap.v(ClinicalSpace.md),

            // Severity filter.
            Container(
              decoration: BoxDecoration(
                color: ClinicalPalette.surface,
                border: Border.all(color: ClinicalPalette.border),
                borderRadius: BorderRadius.circular(ClinicalRadii.tile),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: <Widget>[
                  for (final (sev, label) in _severities)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _severityFilter = sev),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sev == _severityFilter
                                ? ClinicalPalette.accent
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(ClinicalRadii.chip),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: sev == _severityFilter
                                  ? Colors.white
                                  : ClinicalPalette.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap.v(ClinicalSpace.md),

            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(ClinicalSpace.xl),
                decoration: BoxDecoration(
                  color: ClinicalPalette.surface,
                  border: Border.all(color: ClinicalPalette.border),
                  borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                ),
                child: const Center(
                  child: Text(
                    'No matching errata.',
                    style: TextStyle(color: ClinicalPalette.muted, fontSize: 13),
                  ),
                ),
              )
            else if (context.isWide)
              // Wide: 2-column masonry-ish grid via Wrap + half-width
              // tiles. Each tile retains its own expand/collapse state.
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = (constraints.maxWidth - ClinicalSpace.sm) / 2;
                  return Wrap(
                    spacing: ClinicalSpace.sm,
                    runSpacing: ClinicalSpace.sm,
                    children: <Widget>[
                      for (final e in filtered)
                        SizedBox(
                          width: w,
                          child: _ErrataRow(entry: e),
                        ),
                    ],
                  );
                },
              )
            else
              for (final e in filtered) ...<Widget>[
                _ErrataRow(entry: e),
                const Gap.v(ClinicalSpace.sm),
              ],

            const Gap.v(ClinicalSpace.md),

            Container(
              padding: const EdgeInsets.fromLTRB(
                ClinicalSpace.md + 2,
                ClinicalSpace.md,
                ClinicalSpace.md + 2,
                ClinicalSpace.md,
              ),
              decoration: BoxDecoration(
                color: ClinicalPalette.surface,
                border: Border.all(color: ClinicalPalette.border),
                borderRadius: BorderRadius.circular(ClinicalRadii.tile),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'REPORT A NEW ISSUE',
                    style: ClinicalText.eyebrow,
                  ),
                  const Gap.v(ClinicalSpace.xs),
                  Text(
                    'Found something wrong with a rule? Email '
                    'errata@psychswitch.health with the rule id and a '
                    'short description. No patient data.',
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

class _ErrataRow extends StatefulWidget {
  const _ErrataRow({required this.entry});
  final ErrataEntry entry;

  @override
  State<_ErrataRow> createState() => _ErrataRowState();
}

class _ErrataRowState extends State<_ErrataRow> {
  bool _expanded = false;

  Color _toneFor(ErrataSeverity s) {
    switch (s) {
      case ErrataSeverity.critical:
        return ClinicalPalette.danger;
      case ErrataSeverity.significant:
        return ClinicalPalette.warning;
      case ErrataSeverity.moderate:
        return ClinicalPalette.accent;
      case ErrataSeverity.minor:
        return ClinicalPalette.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final tone = _toneFor(e.severity);

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: ClinicalPalette.border),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.md + 2,
                  ClinicalSpace.md - 2,
                  ClinicalSpace.md + 2,
                  ClinicalSpace.md - 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${e.dateISO} · v${e.appVersion}',
                            style: ClinicalText.eyebrow,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ClinicalSpace.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.16),
                            border: Border.all(
                              color: tone.withValues(alpha: 0.3),
                            ),
                            borderRadius:
                                BorderRadius.circular(ClinicalRadii.pill),
                          ),
                          child: Text(
                            severityLabel(e.severity).toUpperCase(),
                            style: TextStyle(
                              color: tone,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap.v(ClinicalSpace.xs + 2),
                    Text(
                      e.summary,
                      style: const TextStyle(
                        color: ClinicalPalette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const Gap.v(2),
                    Text(
                      '${e.scopeLabel} · ${changeKindLabel(e.changeKind)}',
                      style: ClinicalText.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: ClinicalPalette.border),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      ClinicalSpace.md + 2,
                      ClinicalSpace.md,
                      ClinicalSpace.md + 2,
                      ClinicalSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('DETAIL', style: ClinicalText.eyebrow),
                        const Gap.v(ClinicalSpace.xs),
                        Text(
                          e.detail,
                          style: const TextStyle(
                            color: ClinicalPalette.text,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (e.before != null || e.after != null) ...<Widget>[
                          const Gap.v(ClinicalSpace.md),
                          const Text('DIFF', style: ClinicalText.eyebrow),
                          const Gap.v(ClinicalSpace.xs),
                          if (e.before != null)
                            _DiffLine(
                              text: e.before!,
                              prefix: '−',
                              tone: ClinicalPalette.danger,
                            ),
                          if (e.after != null) ...<Widget>[
                            const Gap.v(2),
                            _DiffLine(
                              text: e.after!,
                              prefix: '+',
                              tone: ClinicalPalette.toneMintInk,
                            ),
                          ],
                        ],
                        const Gap.v(ClinicalSpace.md),
                        const Text('RATIONALE', style: ClinicalText.eyebrow),
                        const Gap.v(ClinicalSpace.xs),
                        Text(
                          e.rationale,
                          style: const TextStyle(
                            color: ClinicalPalette.text,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (e.citations.isNotEmpty) ...<Widget>[
                          const Gap.v(ClinicalSpace.md),
                          const Text(
                            'CITATIONS',
                            style: ClinicalText.eyebrow,
                          ),
                          const Gap.v(ClinicalSpace.xs),
                          for (final c in e.citations)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                '· $c',
                                style: ClinicalText.caption.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                        const Gap.v(ClinicalSpace.md),
                        Text(
                          'Reviewer: ${e.reviewer} · scope: ${e.scope}',
                          style: ClinicalText.eyebrow.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({
    required this.text,
    required this.prefix,
    required this.tone,
  });
  final String text;
  final String prefix;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: tone, width: 2),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.sm + 2,
        ClinicalSpace.xs,
        ClinicalSpace.sm + 2,
        ClinicalSpace.xs + 2,
      ),
      child: Text(
        '$prefix $text',
        style: const TextStyle(
          color: ClinicalPalette.text,
          fontSize: 11,
          height: 1.5,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
