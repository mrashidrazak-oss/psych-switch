// DSM-5-TR criterion runner — tick the criteria, see live group-level
// satisfaction, copy a clipboard-ready summary for the note.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/dsm.dart';

class DsmRunnerScreen extends StatefulWidget {
  const DsmRunnerScreen({super.key, required this.disorderId});
  final String disorderId;

  @override
  State<DsmRunnerScreen> createState() => _DsmRunnerScreenState();
}

class _DsmRunnerScreenState extends State<DsmRunnerScreen> {
  final Set<String> _ticked = <String>{};

  DsmDisorder? get _disorder => dsmById(widget.disorderId);

  void _toggle(String id) {
    setState(() {
      if (_ticked.contains(id)) {
        _ticked.remove(id);
      } else {
        _ticked.add(id);
      }
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_ticked.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final d = _disorder;
    if (d == null) return const _UnknownDisorderScreen();
    final eval = evaluateDsm(d, _ticked);

    return Scaffold(
      appBar: AppBar(
        title: Text(d.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_ticked.isNotEmpty)
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _VerdictBanner(evaluation: eval),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  for (var i = 0; i < eval.groups.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: ClinicalSpace.md),
                    _GroupCard(
                      eval: eval.groups[i],
                      ticked: _ticked,
                      onToggle: _toggle,
                    ),
                  ],
                  const SizedBox(height: ClinicalSpace.lg),
                  _SummaryCard(evaluation: eval),
                  if (d.exclusionNote != null) ...<Widget>[
                    const SizedBox(height: ClinicalSpace.md),
                    SquircleCard(
                      tone: ClinicalPalette.surfaceMuted,
                      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.report_problem_outlined,
                              size: 16,
                              color: ClinicalPalette.mutedStrong),
                          const SizedBox(width: ClinicalSpace.sm + 2),
                          Expanded(
                            child: Text(
                              d.exclusionNote!,
                              style: ClinicalText.caption
                                  .copyWith(height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: ClinicalSpace.md),
                  Text(
                    d.citation,
                    textAlign: TextAlign.center,
                    style: ClinicalText.caption
                        .copyWith(color: ClinicalPalette.muted),
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

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.evaluation});
  final DsmEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final met = evaluation.metAll;
    final tone = met ? ClinicalPalette.toneMint : ClinicalPalette.toneSand;
    final ink = met
        ? ClinicalPalette.toneMintInk
        : ClinicalPalette.toneSandInk;
    final groupsMet =
        evaluation.groups.where((g) => g.met).length;
    return Container(
      width: double.infinity,
      color: tone,
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.md,
        ClinicalSpace.lg + 4,
        ClinicalSpace.md + 2,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              met ? Icons.check_rounded : Icons.access_time_rounded,
              color: ink,
            ),
          ),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  met
                      ? 'Criteria appear met'
                      : '$groupsMet of ${evaluation.groups.length} groups met',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  met
                      ? 'Confirm exclusions + functional impairment.'
                      : 'Tap criteria to tally each group.',
                  style: ClinicalText.caption
                      .copyWith(color: ink.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.eval,
    required this.ticked,
    required this.onToggle,
  });

  final GroupEvaluation eval;
  final Set<String> ticked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final met = eval.met;
    final headerInk = met
        ? ClinicalPalette.toneMintInk
        : ClinicalPalette.mutedStrong;
    final headerTone = met
        ? ClinicalPalette.toneMint
        : ClinicalPalette.surfaceMuted;
    return SquircleCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Container(
            color: headerTone,
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md,
              ClinicalSpace.lg,
              ClinicalSpace.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        eval.group.label.toUpperCase(),
                        style: ClinicalText.eyebrow.copyWith(
                          color: headerInk,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eval.group.requirement,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: headerInk,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ClinicalSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClinicalSpace.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                  ),
                  child: Text(
                    met ? 'MET' : '${eval.hits} ticked',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: headerInk,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (eval.group.headerNote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClinicalSpace.lg,
                ClinicalSpace.md,
                ClinicalSpace.lg,
                0,
              ),
              child: Text(
                eval.group.headerNote!,
                style: ClinicalText.caption.copyWith(height: 1.5),
              ),
            ),
          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.md,
              ClinicalSpace.sm,
              ClinicalSpace.md,
              ClinicalSpace.md,
            ),
            child: Column(
              children: <Widget>[
                for (final c in eval.group.criteria)
                  _CriterionRow(
                    criterion: c,
                    checked: ticked.contains(c.id),
                    onToggle: () => onToggle(c.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.criterion,
    required this.checked,
    required this.onToggle,
  });

  final DsmCriterion criterion;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.sm,
          vertical: ClinicalSpace.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked
                    ? ClinicalPalette.cta
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked
                      ? ClinicalPalette.cta
                      : ClinicalPalette.borderStrong,
                  width: 1.2,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: ClinicalPalette.ctaText,
                    )
                  : null,
            ),
            const SizedBox(width: ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    criterion.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          checked ? FontWeight.w700 : FontWeight.w500,
                      color: ClinicalPalette.text,
                      height: 1.45,
                    ),
                  ),
                  if (criterion.note != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      criterion.note!,
                      style: ClinicalText.caption.copyWith(
                        color: ClinicalPalette.warning,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.evaluation});
  final DsmEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Note-ready summary',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            evaluation.summary(),
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy to clipboard',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: evaluation.summary()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UnknownDisorderScreen extends StatelessWidget {
  const _UnknownDisorderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text("We couldn't find that disorder."),
      ),
    );
  }
}
