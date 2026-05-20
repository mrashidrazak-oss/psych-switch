// Side-by-side drug comparison.
//
// Pick two drugs from the registry → matrix of every clinically
// meaningful attribute laid out as two columns:
//
//   • Half-life (parent + active metabolite)
//   • Sedation, EPS, prolactin, QTc, metabolic risk
//   • Anticholinergic burden tier
//   • CYP inhibition profile (a hot question for SSRI ↔ antipsychotic
//     co-prescription)
//   • Discontinuation-syndrome risk
//   • MAOI washout (if applicable)
//   • Malaysian brand names (one-tap memory aid)
//
// Built for the moment a registrar asks "should I switch this patient
// from paroxetine to sertraline?" — open the comparator, scan the
// rows, decide. No clicking through two separate profiles.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/anticholinergic.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  String? _leftId;
  String? _rightId;

  void _pick({required bool left, required String id}) {
    setState(() {
      if (left) {
        _leftId = id;
      } else {
        _rightId = id;
      }
    });
    unawaited(hapticsTap());
  }

  void _swap() {
    setState(() {
      final tmp = _leftId;
      _leftId = _rightId;
      _rightId = tmp;
    });
    unawaited(hapticsTap());
  }

  void _clear() {
    setState(() {
      _leftId = null;
      _rightId = null;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final engineAsync = ref.watch(engineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_leftId != null || _rightId != null)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
            ),
        ],
      ),
      body: SafeArea(
        child: engineAsync.when(
          loading: () => const EngineLoadingView(),
          error: (e, _) => EngineErrorView(error: e),
          data: (engine) => _Body(
            engine: engine,
            leftId: _leftId,
            rightId: _rightId,
            onPick: (left, id) => _pick(left: left, id: id),
            onSwap: _swap,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.engine,
    required this.leftId,
    required this.rightId,
    required this.onPick,
    required this.onSwap,
  });

  final SwitchingEngine engine;
  final String? leftId;
  final String? rightId;
  // Function-type signatures don't reasonably accept named params in
  // typedef-free declarations.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool left, String id) onPick;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final left = leftId == null ? null : engine.getDrug(leftId!);
    final right = rightId == null ? null : engine.getDrug(rightId!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.lg,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      children: <Widget>[
        _Hero(left: left, right: right),
        const Gap.v(ClinicalSpace.lg),
        _PickerRow(
          engine: engine,
          left: left,
          right: right,
          onPick: onPick,
          onSwap: onSwap,
        ),
        if (left != null && right != null) ...<Widget>[
          const Gap.v(ClinicalSpace.lg),
          _Matrix(left: left, right: right),
        ],
        const Gap.v(ClinicalSpace.lg),
        const _FooterNote(),
      ],
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({this.left, this.right});

  final Drug? left;
  final Drug? right;

  @override
  Widget build(BuildContext context) {
    final ready = left != null && right != null;
    final tone = ready ? ClinicalPalette.accent : ClinicalPalette.muted;

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md + 2,
              ClinicalSpace.md,
              ClinicalSpace.md + 2,
            ),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(ClinicalRadii.card),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(ClinicalRadii.chip),
                  ),
                  child: Icon(Icons.compare_arrows, color: tone, size: 20),
                ),
                const Gap.h(ClinicalSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Compare two drugs',
                        style: ClinicalText.subtitle.copyWith(
                          color: ClinicalPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap.v(ClinicalSpace.xs - 1),
                      Text(
                        ready
                            ? 'Half-life · sedation · EPS · metabolic · QTc · ACB'
                            : 'Pick two drugs to compare side-by-side',
                        style: ClinicalText.caption.copyWith(
                          color: ClinicalPalette.mutedStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Picker row ──────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.engine,
    required this.left,
    required this.right,
    required this.onPick,
    required this.onSwap,
  });

  final SwitchingEngine engine;
  final Drug? left;
  final Drug? right;
  // Function-type signatures don't reasonably accept named params in
  // typedef-free declarations.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool left, String id) onPick;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: _DrugSlot(
            tone: ClinicalPalette.toneLavenderInk,
            label: 'Drug A',
            drug: left,
            onTap: () => _openPicker(context, isLeft: true),
          ),
        ),
        const Gap.h(ClinicalSpace.sm),
        _SwapButton(enabled: left != null && right != null, onPressed: onSwap),
        const Gap.h(ClinicalSpace.sm),
        Expanded(
          child: _DrugSlot(
            tone: ClinicalPalette.toneMintInk,
            label: 'Drug B',
            drug: right,
            onTap: () => _openPicker(context, isLeft: false),
          ),
        ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context, {required bool isLeft}) async {
    unawaited(hapticsTap());
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ClinicalPalette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ClinicalRadii.card)),
      ),
      builder: (_) => _DrugPickerSheet(engine: engine),
    );
    if (picked != null) onPick(isLeft, picked);
  }
}

class _DrugSlot extends StatelessWidget {
  const _DrugSlot({
    required this.tone,
    required this.label,
    required this.drug,
    required this.onTap,
  });

  final Color tone;
  final String label;
  final Drug? drug;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md,
          vertical: ClinicalSpace.md + 2,
        ),
        decoration: BoxDecoration(
          color: ClinicalPalette.surface,
          border: Border.all(
            color: tone.withValues(alpha: 0.45),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: ClinicalText.eyebrow.copyWith(color: tone),
            ),
            const Gap.v(ClinicalSpace.xs),
            Text(
              drug?.genericName ?? 'Tap to pick',
              style: ClinicalText.subtitle.copyWith(
                color: drug == null ? ClinicalPalette.muted : ClinicalPalette.text,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (drug != null) ...<Widget>[
              const Gap.v(ClinicalSpace.xs - 1),
              Text(
                drug!.drugClass,
                style: ClinicalText.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClinicalPalette.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: SizedBox(
          width: 44,
          child: Icon(
            Icons.swap_horiz_rounded,
            color: enabled ? ClinicalPalette.accent : ClinicalPalette.muted,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Matrix ──────────────────────────────────────────────────────────

class _Matrix extends StatelessWidget {
  const _Matrix({required this.left, required this.right});

  final Drug left;
  final Drug right;

  @override
  Widget build(BuildContext context) {
    final rows = <_MatrixRow>[
      _MatrixRow(
        'Half-life',
        _fmtHalfLife(left),
        _fmtHalfLife(right),
      ),
      _MatrixRow(
        'Active metabolite',
        _fmtMetabolite(left),
        _fmtMetabolite(right),
      ),
      _MatrixRow(
        'Sedation',
        _fmtRisk(left.sedation),
        _fmtRisk(right.sedation),
      ),
      _MatrixRow(
        'EPS risk',
        _fmtRisk(left.epsRisk),
        _fmtRisk(right.epsRisk),
      ),
      _MatrixRow(
        'Prolactin',
        _fmtRisk(left.prolactinRisk),
        _fmtRisk(right.prolactinRisk),
      ),
      _MatrixRow(
        'QTc risk',
        _fmtRisk(left.qtcRisk),
        _fmtRisk(right.qtcRisk),
      ),
      _MatrixRow(
        'Metabolic',
        _fmtRisk(left.metabolicRisk?.score),
        _fmtRisk(right.metabolicRisk?.score),
      ),
      _MatrixRow(
        'Anticholinergic',
        acbTierLabel(acbTierForDrug(left)),
        acbTierLabel(acbTierForDrug(right)),
      ),
      _MatrixRow(
        'Discontinuation',
        _fmtRisk(left.discontinuationSyndromeRisk?.score),
        _fmtRisk(right.discontinuationSyndromeRisk?.score),
      ),
      _MatrixRow(
        'CYP inhibits',
        _fmtCypInhibits(left),
        _fmtCypInhibits(right),
      ),
      _MatrixRow(
        'MAOI washout',
        _fmtMaoi(left),
        _fmtMaoi(right),
      ),
      _MatrixRow(
        'MY brands',
        _fmtBrands(left),
        _fmtBrands(right),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: ClinicalPalette.border.withValues(alpha: 0.7),
              ),
            _MatrixRowView(row: rows[i]),
          ],
        ],
      ),
    );
  }

  String _fmtHalfLife(Drug d) {
    final r = d.halfLife.rangeHours;
    if (r.length >= 2) {
      return '${_h(r.first)}–${_h(r.last)} h';
    }
    return '${_h(d.halfLife.meanHours)} h';
  }

  String _h(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _fmtMetabolite(Drug d) {
    final m = d.activeMetabolite;
    if (m.name == null || m.name!.isEmpty) return '—';
    final h = m.halfLifeHours;
    final star = m.clinicallySignificant ? ' ★' : '';
    if (h == null) return '${m.name}$star';
    return '${m.name} · ${h.toStringAsFixed(0)} h$star';
  }

  String _fmtRisk(RiskLevel? r) => r == null ? '—' : _riskLabel(r);

  String _fmtCypInhibits(Drug d) {
    final ins = d.cypInteractions.inhibitorOf;
    if (ins.isEmpty) return '—';
    return ins.map((c) => c.toUpperCase()).join(', ');
  }

  String _fmtMaoi(Drug d) {
    final w = d.maoiWashout;
    if (w == null) return '—';
    final parts = <String>[];
    if (w.daysOffBeforeMAOI > 0) parts.add('${w.daysOffBeforeMAOI}d before');
    if (w.daysOffAfterMAOI > 0) parts.add('${w.daysOffAfterMAOI}d after');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _fmtBrands(Drug d) {
    if (d.malaysianBrandNames.isEmpty) return '—';
    return d.malaysianBrandNames.take(3).join(', ');
  }
}

String _riskLabel(RiskLevel r) => switch (r) {
      RiskLevel.low => 'Low',
      RiskLevel.lowModerate => 'Low–moderate',
      RiskLevel.moderate => 'Moderate',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'Very high',
    };

class _MatrixRow {
  const _MatrixRow(this.label, this.leftValue, this.rightValue);
  final String label;
  final String leftValue;
  final String rightValue;
}

class _MatrixRowView extends StatelessWidget {
  const _MatrixRowView({required this.row});
  final _MatrixRow row;

  @override
  Widget build(BuildContext context) {
    final differ = row.leftValue != row.rightValue &&
        row.leftValue != '—' &&
        row.rightValue != '—';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.md + 2,
        vertical: ClinicalSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                row.label.toUpperCase(),
                style: ClinicalText.eyebrow,
              ),
              const Spacer(),
              if (differ)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClinicalSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ClinicalPalette.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                  ),
                  child: Text(
                    'DIFFERS',
                    style: ClinicalText.eyebrow.copyWith(
                      color: ClinicalPalette.warning,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs + 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _Cell(text: row.leftValue, tone: ClinicalPalette.toneLavenderInk),
              ),
              const Gap.h(ClinicalSpace.md),
              Expanded(
                child: _Cell(text: row.rightValue, tone: ClinicalPalette.toneMintInk),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.tone});
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final dimmed = text == '—';
    return Text(
      text,
      style: ClinicalText.body.copyWith(
        color: dimmed ? ClinicalPalette.muted : ClinicalPalette.text,
        fontWeight: FontWeight.w600,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

// ── Picker sheet ────────────────────────────────────────────────────

class _DrugPickerSheet extends StatefulWidget {
  const _DrugPickerSheet({required this.engine});
  final SwitchingEngine engine;

  @override
  State<_DrugPickerSheet> createState() => _DrugPickerSheetState();
}

class _DrugPickerSheetState extends State<_DrugPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = widget.engine
        .listDrugs()
        .where((d) => d.formulation != Formulation.lai)
        .toList()
      ..sort((a, b) => a.genericName.compareTo(b.genericName));
    final q = _q.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((d) {
            if (d.genericName.toLowerCase().contains(q)) return true;
            if (d.drugClass.toLowerCase().contains(q)) return true;
            for (final b in d.malaysianBrandNames) {
              if (b.toLowerCase().contains(q)) return true;
            }
            return false;
          }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Gap.v(ClinicalSpace.sm),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: ClinicalPalette.border,
                borderRadius: BorderRadius.circular(ClinicalRadii.pill),
              ),
            ),
            const Gap.v(ClinicalSpace.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: ClinicalSpace.lg),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                style: ClinicalText.body,
                decoration: InputDecoration(
                  hintText: 'Search drugs, class, brand',
                  hintStyle: ClinicalText.body
                      .copyWith(color: ClinicalPalette.muted),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: ClinicalPalette.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg,
                  ClinicalSpace.sm,
                  ClinicalSpace.lg,
                  ClinicalSpace.lg,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: ClinicalPalette.border.withValues(alpha: 0.7),
                ),
                itemBuilder: (context, i) {
                  final d = filtered[i];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(d.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: ClinicalSpace.md,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  d.genericName,
                                  style: ClinicalText.body.copyWith(
                                    color: ClinicalPalette.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(d.drugClass,
                                    style: ClinicalText.caption),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Drug profile',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.info_outline, size: 18),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.pushNamed(
                                Routes.drugProfile,
                                pathParameters: <String, String>{'id': d.id},
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClinicalSpace.md),
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Text(
        'Comparator surfaces structured registry data only. For a full '
        "clinical picture, open each drug's profile via the picker info "
        'button.',
        style: ClinicalText.caption.copyWith(color: ClinicalPalette.mutedStrong),
      ),
    );
  }
}
