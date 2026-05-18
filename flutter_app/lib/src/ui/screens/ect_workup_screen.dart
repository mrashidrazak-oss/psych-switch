// ECT work-up checklist — tick items by group, live completion
// banner, copy the outstanding list.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/ect_workup.dart';

class EctWorkupScreen extends StatefulWidget {
  const EctWorkupScreen({super.key});

  @override
  State<EctWorkupScreen> createState() => _EctWorkupScreenState();
}

class _EctWorkupScreenState extends State<EctWorkupScreen> {
  final Set<String> _ticked = <String>{};

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
    final result = evaluateEct(_ticked);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECT work-up'),
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
            _Banner(result: result),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  for (final g in kEctGroups) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: ClinicalSpace.xs,
                        bottom: ClinicalSpace.sm,
                        top: ClinicalSpace.sm,
                      ),
                      child: Text(g.title.toUpperCase(),
                          style: ClinicalText.eyebrow),
                    ),
                    for (final it in g.items) ...<Widget>[
                      _ItemRow(
                        item: it,
                        ticked: _ticked.contains(it.id),
                        onTap: () => _toggle(it.id),
                      ),
                      const SizedBox(height: 6),
                    ],
                    const SizedBox(height: ClinicalSpace.sm),
                  ],
                  _SummaryCard(result: result),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.result});
  final EctResult result;

  @override
  Widget build(BuildContext context) {
    final done = result.isComplete;
    final tone =
        done ? ClinicalPalette.toneMint : ClinicalPalette.toneSand;
    final ink = done
        ? ClinicalPalette.toneMintInk
        : ClinicalPalette.toneSandInk;
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
          Text(
            '${result.satisfied}',
            style: TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -1,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '/ ${result.totalItems}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(ClinicalRadii.pill),
            ),
            child: Text(
              done ? 'READY' : 'IN PROGRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ink,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.ticked,
    required this.onTap,
  });

  final EctItem item;
  final bool ticked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ticked
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.all(ClinicalSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: ticked ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ticked
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 1.2,
                  ),
                ),
                child: ticked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: ClinicalPalette.cta)
                    : null,
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ticked
                            ? ClinicalPalette.ctaText
                            : ClinicalPalette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: ticked
                            ? ClinicalPalette.ctaText
                                .withValues(alpha: 0.85)
                            : ClinicalPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});
  final EctResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Hand-over',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.isComplete
                ? 'Work-up complete — ready to list for ECT.'
                : '${result.outstanding.length} item(s) outstanding '
                    'before listing.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy checklist',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.clipboardSummary()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checklist copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

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
              'Maudsley 15e / RCPsych ECT Handbook / NICE TA59. '
              'A generic aid — your ECT suite SOP and the '
              'anaesthetic team take precedence.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
