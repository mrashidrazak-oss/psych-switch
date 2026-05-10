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
            AppSpace.lg + 4,
            AppSpace.lg,
            AppSpace.lg + 4,
            AppSpace.xl,
          ),
          children: <Widget>[
            Text(
              '${errataCount()} corrections recorded since v0.1. Every '
              'accepted change is logged with a reviewer signature and '
              'citation. No edits, no quiet rewrites — append-only audit '
              'trail.',
              style: AppTextSizes.caption.copyWith(height: 1.55),
            ),
            const Gap.v(AppSpace.lg),

            // Search.
            TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search rule, drug, summary',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
            const Gap.v(AppSpace.md),

            // Severity filter.
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.lg),
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
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: sev == _severityFilter
                                  ? Colors.white
                                  : AppColors.text,
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
            const Gap.v(AppSpace.md),

            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: const Center(
                  child: Text(
                    'No matching errata.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              )
            else
              for (final e in filtered) ...<Widget>[
                _ErrataRow(entry: e),
                const Gap.v(AppSpace.sm),
              ],

            const Gap.v(AppSpace.md),

            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md + 2,
                AppSpace.md,
                AppSpace.md + 2,
                AppSpace.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'REPORT A NEW ISSUE',
                    style: AppTextSizes.eyebrow,
                  ),
                  const Gap.v(AppSpace.xs),
                  Text(
                    'Found something wrong with a rule? Email '
                    'errata@psychswitch.health with the rule id and a '
                    'short description. No patient data.',
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
        return AppColors.danger;
      case ErrataSeverity.significant:
        return AppColors.warning;
      case ErrataSeverity.moderate:
        return AppColors.accent;
      case ErrataSeverity.minor:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final tone = _toneFor(e.severity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
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
                  AppSpace.md + 2,
                  AppSpace.md - 2,
                  AppSpace.md + 2,
                  AppSpace.md - 2,
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
                            style: AppTextSizes.eyebrow,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.16),
                            border: Border.all(
                              color: tone.withValues(alpha: 0.3),
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill),
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
                    const Gap.v(AppSpace.xs + 2),
                    Text(
                      e.summary,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const Gap.v(2),
                    Text(
                      '${e.scopeLabel} · ${changeKindLabel(e.changeKind)}',
                      style: AppTextSizes.micro,
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
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md + 2,
                      AppSpace.md,
                      AppSpace.md + 2,
                      AppSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('DETAIL', style: AppTextSizes.eyebrow),
                        const Gap.v(AppSpace.xs),
                        Text(
                          e.detail,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (e.before != null || e.after != null) ...<Widget>[
                          const Gap.v(AppSpace.md),
                          const Text('DIFF', style: AppTextSizes.eyebrow),
                          const Gap.v(AppSpace.xs),
                          if (e.before != null)
                            _DiffLine(
                              text: e.before!,
                              prefix: '−',
                              tone: AppColors.danger,
                            ),
                          if (e.after != null) ...<Widget>[
                            const Gap.v(2),
                            _DiffLine(
                              text: e.after!,
                              prefix: '+',
                              tone: AppColors.to,
                            ),
                          ],
                        ],
                        const Gap.v(AppSpace.md),
                        const Text('RATIONALE', style: AppTextSizes.eyebrow),
                        const Gap.v(AppSpace.xs),
                        Text(
                          e.rationale,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (e.citations.isNotEmpty) ...<Widget>[
                          const Gap.v(AppSpace.md),
                          const Text(
                            'CITATIONS',
                            style: AppTextSizes.eyebrow,
                          ),
                          const Gap.v(AppSpace.xs),
                          for (final c in e.citations)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                '· $c',
                                style: AppTextSizes.micro.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                        const Gap.v(AppSpace.md),
                        Text(
                          'Reviewer: ${e.reviewer} · scope: ${e.scope}',
                          style: AppTextSizes.eyebrow.copyWith(
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
        AppSpace.sm + 2,
        AppSpace.xs,
        AppSpace.sm + 2,
        AppSpace.xs + 2,
      ),
      child: Text(
        '$prefix $text',
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
          height: 1.5,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
