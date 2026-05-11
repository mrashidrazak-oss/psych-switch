// Clozapine module — Phase 7C.
//
// Five-tab surface for the highest-stakes drug in the registry:
//
//   • TITRATION  — picker (4 variants by sex × smoking) + day-by-day
//                  morning/evening dose schedule, post-titration
//                  guidance, missed-dose rule, citations.
//   • FBC        — phase table (frequency by week), key milestones,
//                  ANC/WBC threshold reference (standard + BEN).
//   • ANC CHECK  — interactive ANC + WBC entry + BEN toggle → green /
//                  amber / red zone with the engine's reasoning string
//                  and the matching action from the rule.
//   • RECHALLENGE— gap-since-last-dose entry (days + hours) → matched
//                  tier card (instructions, retitration flag, warning
//                  signs).
//   • COMMUNITY  — essential criteria, relative contraindications,
//                  initial workup, monitoring intensity by week-band.
//
// Every tab is read-only except ANC CHECK and RECHALLENGE which run
// engine algorithms on entered values.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/clozapine.dart';
import 'package:psychswitch_engine/patient_context_pure.dart' show Sex;

class ClozapineScreen extends ConsumerStatefulWidget {
  const ClozapineScreen({super.key});

  @override
  ConsumerState<ClozapineScreen> createState() => _ClozapineScreenState();
}

class _ClozapineScreenState extends ConsumerState<ClozapineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtl;

  /// Per-tab lazy-build flags. Only TITRATION (index 0) builds at
  /// mount; the other four tabs build the first time the user lands
  /// on them, then keep their widget state alive thereafter.
  final List<bool> _built = <bool>[true, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _tabCtl = TabController(length: 5, vsync: this)..addListener(_onTab);
  }

  void _onTab() {
    final i = _tabCtl.index;
    if (!_built[i]) {
      setState(() => _built[i] = true);
    }
  }

  @override
  void dispose() {
    _tabCtl
      ..removeListener(_onTab)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCloz = ref.watch(clozapineModuleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clozapine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabCtl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // Tab styling comes from the global TabBarTheme.
          tabs: const <Tab>[
            Tab(text: 'TITRATION'),
            Tab(text: 'FBC'),
            Tab(text: 'ANC CHECK'),
            Tab(text: 'RECHALLENGE'),
            Tab(text: 'COMMUNITY'),
          ],
        ),
      ),
      body: SafeArea(
        child: asyncCloz.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (cloz) => TabBarView(
            controller: _tabCtl,
            children: <Widget>[
              if (_built[0]) _TitrationTab(module: cloz)
              else const SizedBox.shrink(),
              if (_built[1]) _FbcTab(schedule: cloz.getMonitoringSchedule())
              else const SizedBox.shrink(),
              if (_built[2])
                _AncCheckTab(
                  thresholds: cloz.getMonitoringSchedule().fbcThresholds,
                )
              else
                const SizedBox.shrink(),
              if (_built[3]) _RechallengeTab(module: cloz)
              else const SizedBox.shrink(),
              if (_built[4]) _CommunityTab(data: cloz.getCommunityInitiation())
              else const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── TITRATION ─────────────────────────────────────────────────────────

class _TitrationTab extends StatefulWidget {
  const _TitrationTab({required this.module});

  final ClozapineModule module;

  @override
  State<_TitrationTab> createState() => _TitrationTabState();
}

class _TitrationTabState extends State<_TitrationTab> {
  TitrationRegimen _regimen = TitrationRegimen.maudsley15;
  Sex _sex = Sex.male;
  bool _smoker = false;

  /// Sex × smoker variant only matters for the Maudsley-15 four-
  /// variant protocols. The 14th-edition and Community regimens have a
  /// single uniform schedule, so the picker is hidden under those.
  bool get _showVariantPickers => _regimen == TitrationRegimen.maudsley15;

  @override
  Widget build(BuildContext context) {
    final protocol = widget.module.getTitrationFor(
      regimen: _regimen,
      variant: (sex: _sex, smoker: _smoker),
    );
    final summary = regimenSummaries[_regimen]!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: <Widget>[
        const _SectionHeader(text: 'REGIMEN'),
        const SizedBox(height: 8),
        _RegimenSelector(
          selected: _regimen,
          onSelected: (r) {
            unawaited(hapticsTap());
            setState(() => _regimen = r);
          },
        ),
        const SizedBox(height: 12),
        _RegimenReasoningCard(regimen: _regimen, summary: summary),

        if (_showVariantPickers) ...<Widget>[
          const SizedBox(height: 20),
          const _SectionHeader(text: 'PATIENT VARIANT'),
          const SizedBox(height: 8),
          _SegmentedRow<Sex>(
            label: 'Sex',
            options: const <(Sex, String)>[
              (Sex.male, 'Male'),
              (Sex.female, 'Female'),
            ],
            selected: _sex,
            onSelected: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: 12),
          _SegmentedRow<bool>(
            label: 'Smoker',
            options: const <(bool, String)>[
              (false, 'Non-smoker'),
              (true, 'Smoker'),
            ],
            selected: _smoker,
            onSelected: (v) => setState(() => _smoker = v),
          ),
        ],

        const SizedBox(height: 20),
        _ProtocolHeaderCard(protocol: protocol),

        const SizedBox(height: 16),
        const _SectionHeader(text: 'DAY-BY-DAY'),
        const SizedBox(height: 8),
        _TitrationTable(steps: protocol.steps),

        const SizedBox(height: 20),
        _NoteCard(
          eyebrow: 'POST-TITRATION',
          body: protocol.postTitrationGuidance,
        ),
        const SizedBox(height: 12),
        _NoteCard(
          eyebrow: 'MISSED DOSE',
          body: protocol.missedDoseRule,
          tone: AppColors.warning,
        ),

        const SizedBox(height: 20),
        _CitationsList(citations: protocol.citations),
      ],
    );
  }
}

/// Three-way segmented selector for the titration regimen. Active
/// segment lifts to a tone-tinted fill; non-default regimens stay in
/// `accent`-blue (informational), Community sits in `to`-green (the
/// "safer / slower" option).
class _RegimenSelector extends StatelessWidget {
  const _RegimenSelector({
    required this.selected,
    required this.onSelected,
  });

  final TitrationRegimen selected;
  final ValueChanged<TitrationRegimen> onSelected;

  Color _activeTone(TitrationRegimen r) {
    switch (r) {
      case TitrationRegimen.maudsley15:
        return AppColors.accent;
      case TitrationRegimen.maudsley14:
        return AppColors.mutedStrong;
      case TitrationRegimen.community:
        return AppColors.to;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.md + 2),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: <Widget>[
          for (final r in TitrationRegimen.values)
            Expanded(
              child: _RegimenSegment(
                regimen: r,
                isActive: r == selected,
                activeTone: _activeTone(r),
                onTap: () => onSelected(r),
              ),
            ),
        ],
      ),
    );
  }
}

class _RegimenSegment extends StatelessWidget {
  const _RegimenSegment({
    required this.regimen,
    required this.isActive,
    required this.activeTone,
    required this.onTap,
  });

  final TitrationRegimen regimen;
  final bool isActive;
  final Color activeTone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = regimenSummaries[regimen]!;
    final activeColor = isActive ? activeTone : AppColors.muted;
    return Semantics(
      button: true,
      selected: isActive,
      label: '${summary.label} regimen — ${summary.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: isActive
                  ? Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                      width: 0.5,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  summary.label,
                  style: TextStyle(
                    color: isActive ? activeColor : AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  summary.subtitle,
                  style: TextStyle(
                    color: isActive
                        ? activeColor.withValues(alpha: 0.85)
                        : AppColors.muted.withValues(alpha: 0.75),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Surfaces the regimen's clinical reasoning so the picker isn't a
/// blind toggle — same Maudsley-15-style note chrome the rest of the
/// tab uses.
class _RegimenReasoningCard extends StatelessWidget {
  const _RegimenReasoningCard({
    required this.regimen,
    required this.summary,
  });

  final TitrationRegimen regimen;
  final RegimenSummary summary;

  @override
  Widget build(BuildContext context) {
    final tone = switch (regimen) {
      TitrationRegimen.maudsley15 => AppColors.accent,
      TitrationRegimen.maudsley14 => AppColors.mutedStrong,
      TitrationRegimen.community => AppColors.to,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        border: Border(
          left: BorderSide(color: tone, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'WHY ${summary.label.toUpperCase()}',
            style: TextStyle(
              color: tone,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.reasoning,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolHeaderCard extends StatelessWidget {
  const _ProtocolHeaderCard({required this.protocol});

  final TitrationProtocol protocol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Target ${protocol.targetDoseMg.toInt()} mg/day · '
                '${protocol.totalDays} days',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            protocol.rationale,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitrationTable extends StatelessWidget {
  const _TitrationTable({required this.steps});

  final List<TitrationStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          const _TitrationRow(
            isHeader: true,
            day: 'Day',
            am: 'AM',
            pm: 'PM',
            total: 'Total',
            notes: 'Notes',
          ),
          const Divider(height: 1, color: AppColors.border),
          ...steps.map(
            (s) => Column(
              children: <Widget>[
                _TitrationRow(
                  day: s.day.toString(),
                  am: _doseLabel(s.morningMg),
                  pm: _doseLabel(s.eveningMg),
                  total: _doseLabel(s.totalMg),
                  notes: s.notes ?? '',
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _doseLabel(num n) {
    if (n == 0) return '—';
    if (n is int || n == n.toInt()) return n.toInt().toString();
    return n.toString();
  }
}

class _TitrationRow extends StatelessWidget {
  const _TitrationRow({
    required this.day,
    required this.am,
    required this.pm,
    required this.total,
    required this.notes,
    this.isHeader = false,
  });

  final String day;
  final String am;
  final String pm;
  final String total;
  final String notes;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final color = isHeader ? AppColors.muted : AppColors.text;
    final weight = isHeader ? FontWeight.w600 : FontWeight.w500;
    final size = isHeader ? 11.0 : 13.0;
    final letterSpacing = isHeader ? 1.5 : 0.0;
    final style = TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text(
              isHeader ? day.toUpperCase() : day,
              style: style,
            ),
          ),
          SizedBox(width: 44, child: Text(isHeader ? am.toUpperCase() : am, style: style)),
          SizedBox(width: 44, child: Text(isHeader ? pm.toUpperCase() : pm, style: style)),
          SizedBox(width: 56, child: Text(isHeader ? total.toUpperCase() : total, style: style)),
          Expanded(
            child: Text(
              isHeader ? notes.toUpperCase() : notes,
              style: style.copyWith(
                color: isHeader ? AppColors.muted : AppColors.muted,
                fontSize: isHeader ? 11 : 11.5,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── FBC ────────────────────────────────────────────────────────────────

class _FbcTab extends StatelessWidget {
  const _FbcTab({required this.schedule});

  final MonitoringScheduleData schedule;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: <Widget>[
        Text(
          schedule.rationale,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        const _SectionHeader(text: 'PHASES'),
        const SizedBox(height: 8),
        ...schedule.phases.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PhaseCard(phase: p),
          ),
        ),

        const SizedBox(height: 12),
        const _SectionHeader(text: 'KEY MILESTONES'),
        const SizedBox(height: 8),
        ...schedule.milestones.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MilestoneCard(milestone: m),
          ),
        ),

        const SizedBox(height: 12),
        const _SectionHeader(text: 'THRESHOLDS · STANDARD'),
        const SizedBox(height: 8),
        _ThresholdsCard(
          thresholds: schedule.fbcThresholds,
          ben: false,
        ),
        const SizedBox(height: 8),
        const _SectionHeader(text: 'THRESHOLDS · BEN-ADJUSTED'),
        const SizedBox(height: 8),
        _ThresholdsCard(
          thresholds: schedule.fbcThresholds,
          ben: true,
        ),
        const SizedBox(height: 8),
        Text(
          schedule.fbcThresholds.benAdjustment.notes,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 20),
        _CitationsList(citations: schedule.citations),
      ],
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase});

  final MonitoringPhase phase;

  @override
  Widget build(BuildContext context) {
    final span = phase.weekEnd != null
        ? 'Wk ${phase.weekStart}–${phase.weekEnd}'
        : 'Wk ${phase.weekStart}+';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                phase.phase.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              Text(
                span,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${phase.frequency} · ${phase.test}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (phase.notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              phase.notes,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone});

  final MonitoringMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            milestone.timepoint.toUpperCase(),
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            milestone.tests.join(' · '),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            milestone.criticalNotes,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdsCard extends StatelessWidget {
  const _ThresholdsCard({required this.thresholds, required this.ben});

  final FbcThresholds thresholds;
  final bool ben;

  @override
  Widget build(BuildContext context) {
    final ancGreen = ben
        ? thresholds.benAdjustment.ancGreenAtOrAbove
        : thresholds.ancGreenAtOrAbove;
    final ancAmberLow = ben
        ? thresholds.benAdjustment.ancAmberRange.low
        : thresholds.ancAmberRange.low;
    final ancAmberHigh = ben
        ? thresholds.benAdjustment.ancAmberRange.high
        : thresholds.ancAmberRange.high;
    final ancRed = ben
        ? thresholds.benAdjustment.ancRedBelow
        : thresholds.ancRedBelow;
    final wbcGreen = ben
        ? thresholds.benAdjustment.wbcGreenAtOrAbove
        : thresholds.wbcGreenAtOrAbove;
    final wbcAmberLow = ben
        ? thresholds.benAdjustment.wbcAmberRange.low
        : thresholds.wbcAmberRange.low;
    final wbcAmberHigh = ben
        ? thresholds.benAdjustment.wbcAmberRange.high
        : thresholds.wbcAmberRange.high;
    final wbcRed = ben
        ? thresholds.benAdjustment.wbcRedBelow
        : thresholds.wbcRedBelow;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ThresholdRow(
            zone: 'GREEN',
            color: AppColors.to,
            anc: '≥ $ancGreen',
            wbc: '≥ $wbcGreen',
          ),
          const SizedBox(height: 6),
          _ThresholdRow(
            zone: 'AMBER',
            color: AppColors.warning,
            anc: '$ancAmberLow–$ancAmberHigh',
            wbc: '$wbcAmberLow–$wbcAmberHigh',
          ),
          const SizedBox(height: 6),
          _ThresholdRow(
            zone: 'RED',
            color: AppColors.danger,
            anc: '< $ancRed',
            wbc: '< $wbcRed',
          ),
          const SizedBox(height: 8),
          Text(
            'Units: ${thresholds.unit}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({
    required this.zone,
    required this.color,
    required this.anc,
    required this.wbc,
  });

  final String zone;
  final Color color;
  final String anc;
  final String wbc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            zone,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'ANC $anc',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Text(
            'WBC $wbc',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

// ── ANC CHECK ─────────────────────────────────────────────────────────

class _AncCheckTab extends StatefulWidget {
  const _AncCheckTab({required this.thresholds});

  final FbcThresholds thresholds;

  @override
  State<_AncCheckTab> createState() => _AncCheckTabState();
}

class _AncCheckTabState extends State<_AncCheckTab> {
  final _ancCtl = TextEditingController();
  final _wbcCtl = TextEditingController();
  bool _ben = false;
  FbcClassification? _result;

  @override
  void dispose() {
    _ancCtl.dispose();
    _wbcCtl.dispose();
    super.dispose();
  }

  void _classify() {
    final anc = double.tryParse(_ancCtl.text);
    final wbc = double.tryParse(_wbcCtl.text);
    if (anc == null || wbc == null) {
      setState(() => _result = null);
      return;
    }
    final next = classifyFbc(
      ancE9PerL: anc,
      wbcE9PerL: wbc,
      thresholds: widget.thresholds,
      applyBen: _ben,
    );
    // Fire haptic only when the zone *changes* — and louder for red.
    if (next.zone != _result?.zone) {
      switch (next.zone) {
        case FbcZone.red:
          unawaited(hapticsWarning());
        case FbcZone.amber:
          unawaited(hapticsConfirm());
        case FbcZone.green:
          unawaited(hapticsTap());
      }
    }
    setState(() => _result = next);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: <Widget>[
        const Text(
          'Enter the latest ANC and WBC. Toggle BEN if the patient has '
          'documented benign ethnic neutropenia — thresholds adjust to '
          'the BEN scheme.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        _NumberField(
          controller: _ancCtl,
          label: 'ANC (×10⁹/L)',
          onChanged: (_) => _classify(),
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _wbcCtl,
          label: 'WBC (×10⁹/L)',
          onChanged: (_) => _classify(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Benign ethnic neutropenia (BEN)',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: const Text(
            'Apply BEN-adjusted thresholds.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          value: _ben,
          activeThumbColor: AppColors.accent,
          onChanged: (v) {
            setState(() => _ben = v);
            _classify();
          },
        ),

        const SizedBox(height: 12),
        if (_result != null) _ZoneCard(
          classification: _result!,
          actions: widget.thresholds.actions,
        ),
      ],
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.classification, required this.actions});

  final FbcClassification classification;
  final FbcActions actions;

  @override
  Widget build(BuildContext context) {
    final (color, action) = switch (classification.zone) {
      FbcZone.green => (AppColors.to, actions.green),
      FbcZone.amber => (AppColors.warning, actions.amber),
      FbcZone.red => (AppColors.danger, actions.red),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            classification.zone.jsonValue.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            classification.reason,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ACTION',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── RECHALLENGE ───────────────────────────────────────────────────────

class _RechallengeTab extends StatefulWidget {
  const _RechallengeTab({required this.module});

  final ClozapineModule module;

  @override
  State<_RechallengeTab> createState() => _RechallengeTabState();
}

class _RechallengeTabState extends State<_RechallengeTab> {
  final _daysCtl = TextEditingController();
  final _hoursCtl = TextEditingController();
  RechallengeTier? _tier;

  @override
  void dispose() {
    _daysCtl.dispose();
    _hoursCtl.dispose();
    super.dispose();
  }

  void _classify() {
    final d = int.tryParse(_daysCtl.text) ?? 0;
    final h = int.tryParse(_hoursCtl.text) ?? 0;
    if (d == 0 && h == 0 && _daysCtl.text.isEmpty && _hoursCtl.text.isEmpty) {
      setState(() => _tier = null);
      return;
    }
    setState(() {
      _tier = widget.module.classifyInterruption(days: d, hours: h);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = widget.module.getRechallengeRules();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: <Widget>[
        Text(
          rules.rationale,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberField(
                controller: _daysCtl,
                label: 'Days missed',
                onChanged: (_) => _classify(),
                allowDecimal: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                controller: _hoursCtl,
                label: 'Extra hours',
                onChanged: (_) => _classify(),
                allowDecimal: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tier != null) _RechallengeTierCard(tier: _tier!),

        const SizedBox(height: 24),
        const _SectionHeader(text: 'ABSOLUTE CONTRAINDICATIONS'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rules.absoluteContraindications
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.block,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 20),
        _CitationsList(citations: rules.citations),
      ],
    );
  }
}

class _RechallengeTierCard extends StatelessWidget {
  const _RechallengeTierCard({required this.tier});

  final RechallengeTier tier;

  Color _colorFor(SafetySeverityLevel s) => switch (s) {
        SafetySeverityLevel.info => AppColors.to,
        SafetySeverityLevel.warning => AppColors.warning,
        SafetySeverityLevel.danger => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(tier.severity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tier.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tier.heading,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tier.guidance,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          _LabelLine(label: 'Restart', body: tier.restartInstruction),
          const SizedBox(height: 8),
          _LabelLine(
            label: 'Re-titration',
            body: tier.retitrationRequired
                ? 'Required — start over.'
                : 'Not required.',
          ),
          const SizedBox(height: 8),
          _LabelLine(label: 'Monitoring', body: tier.monitoringNote),
          const SizedBox(height: 10),
          const Text(
            'WATCH FOR',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          ...tier.warningSignsToWatch.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '• $s',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelLine extends StatelessWidget {
  const _LabelLine({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ── COMMUNITY ─────────────────────────────────────────────────────────

class _CommunityTab extends StatelessWidget {
  const _CommunityTab({required this.data});

  final CommunityInitiationData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: <Widget>[
        Text(
          data.rationale,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        const _SectionHeader(text: 'ESSENTIAL CRITERIA'),
        const SizedBox(height: 8),
        ...data.essentialCriteria.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CriterionCard(item: c, tone: AppColors.to),
          ),
        ),

        const SizedBox(height: 12),
        const _SectionHeader(text: 'RELATIVE CONTRAINDICATIONS'),
        const SizedBox(height: 8),
        ...data.relativeContraindications.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CriterionCard(item: c, tone: AppColors.warning),
          ),
        ),

        const SizedBox(height: 12),
        const _SectionHeader(text: 'INITIAL WORKUP'),
        const SizedBox(height: 8),
        ...data.initialWorkup.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CriterionCard(item: c, tone: AppColors.accent),
          ),
        ),

        const SizedBox(height: 12),
        const _SectionHeader(text: 'MONITORING INTENSITY'),
        const SizedBox(height: 8),
        _MonitoringIntensityCard(intensity: data.monitoringIntensity),

        const SizedBox(height: 20),
        _CitationsList(citations: data.citations),
      ],
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({required this.item, required this.tone});

  final CommunityInitiationCriterion item;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              item.detail,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringIntensityCard extends StatelessWidget {
  const _MonitoringIntensityCard({required this.intensity});

  final CommunityMonitoringIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('First 4 weeks', intensity.first4Weeks),
      ('Weeks 5–18', intensity.weeks5To18),
      ('Weeks 19–52', intensity.weeks19To52),
      ('Year 2+', intensity.year2Onwards),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      r.$1.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.$2,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── SHARED ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextSizes.eyebrow);
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap.v(AppSpace.xs + 2),
        Wrap(
          spacing: AppSpace.xs + 2,
          runSpacing: AppSpace.xs + 2,
          children: options.map((opt) {
            final value = opt.$1;
            final text = opt.$2;
            final isSelected = value == selected;
            return Material(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm + 2),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(value),
                child: Ink(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppRadii.sm + 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.accent : AppColors.text,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.allowDecimal = true,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: <TextInputFormatter>[
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(color: AppColors.text, fontSize: 15),
      // Decoration borders + fill come from the global InputDecorationTheme.
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.eyebrow,
    required this.body,
    this.tone = AppColors.accent,
  });

  final String eyebrow;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md + 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow.toUpperCase(),
            style: AppTextSizes.eyebrow.copyWith(
              color: tone,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const Gap.v(AppSpace.xs),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationsList extends StatelessWidget {
  const _CitationsList({required this.citations});

  final List<String> citations;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeader(text: 'CITATIONS'),
        const Gap.v(AppSpace.xs + 2),
        ...citations.map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $c',
              style: AppTextSizes.micro.copyWith(
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
