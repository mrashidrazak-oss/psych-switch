// Depot LAI module — Phase 7D.
//
// Two surfaces:
//   • DepotIndexScreen  — `/depot`. Cards for the three reviewed
//     once-monthly / quarterly LAI protocols: Invega Sustenna (PP1M),
//     Invega Trinza (PP3M), Abilify Maintena.
//   • DepotProtocolScreen — `/depot/<id>`. Renders one of the three
//     protocols. Sections vary by agent (eligibility on Trinza, two
//     initiation methods on Maintena, drug-interaction table on
//     Maintena, etc.) but every protocol gets:
//       overview · oral pre-treatment · initiation · maintenance ·
//       needle guide · missed-dose flows · organ-function notes ·
//       PK notes · key warnings · citations.
//
// All clinical content lives in psychswitch_engine/lib/src/depot_lai.dart
// as `const` instances — this screen is purely presentational.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/depot_lai.dart';

/// Identifies one of the three depot protocols. Used as the `:id` URL
/// segment for `/depot/:id`.
enum DepotKind {
  sustenna,
  trinza,
  maintena;

  static DepotKind? parse(String? raw) {
    if (raw == null) return null;
    for (final v in DepotKind.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

// ── INDEX ─────────────────────────────────────────────────────────────

class DepotIndexScreen extends StatelessWidget {
  const DepotIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depot LAI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.xl,
            AppSpace.xl,
            AppSpace.xl,
          ),
          children: <Widget>[
            Text(
              'Once-monthly and quarterly LAI antipsychotics. Reviewed '
              'against FDA labelling and Maudsley 15. Each protocol has '
              'its own initiation rules, missed-dose flows, and needle '
              'guidance — read the agent before mixing them up.',
              style: AppTextSizes.caption.copyWith(height: 1.55),
            ),
            const Gap.v(AppSpace.lg + 4),
            _DepotIndexCard(
              title: sustenna.brandName,
              subtitle: sustenna.genericName,
              indication: sustenna.indication,
              interval: sustenna.injectionInterval,
              onTap: () =>
                  context.pushNamed(Routes.depot, pathParameters: <String, String>{
                'id': DepotKind.sustenna.name,
              }),
            ),
            const Gap.v(AppSpace.md),
            _DepotIndexCard(
              title: trinza.brandName,
              subtitle: trinza.genericName,
              indication: trinza.indication,
              interval: trinza.injectionInterval,
              onTap: () =>
                  context.pushNamed(Routes.depot, pathParameters: <String, String>{
                'id': DepotKind.trinza.name,
              }),
            ),
            const Gap.v(AppSpace.md),
            _DepotIndexCard(
              title: maintena.brandName,
              subtitle: maintena.genericName,
              indication: maintena.indication,
              interval: maintena.injectionInterval,
              onTap: () =>
                  context.pushNamed(Routes.depot, pathParameters: <String, String>{
                'id': DepotKind.maintena.name,
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepotIndexCard extends StatelessWidget {
  const _DepotIndexCard({
    required this.title,
    required this.subtitle,
    required this.indication,
    required this.interval,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String indication;
  final String interval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md + 2,
            AppSpace.md + 2,
            AppSpace.md + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm + 2),
                ),
                child: const Icon(
                  Icons.colorize_outlined,
                  color: AppColors.accent,
                  size: 18,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Gap.v(2),
                    Text(subtitle, style: AppTextSizes.micro),
                    const Gap.v(AppSpace.sm),
                    Text(
                      indication,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const Gap.v(AppSpace.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm + 2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                        borderRadius:
                            BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.schedule,
                            size: 11,
                            color: AppColors.accent,
                          ),
                          const Gap.h(AppSpace.xs),
                          Text(
                            interval,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DETAIL ────────────────────────────────────────────────────────────

class DepotProtocolScreen extends StatelessWidget {
  const DepotProtocolScreen({super.key, required this.kind});

  final DepotKind kind;

  String get _title => switch (kind) {
        DepotKind.sustenna => sustenna.brandName,
        DepotKind.trinza => trinza.brandName,
        DepotKind.maintena => maintena.brandName,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: switch (kind) {
            DepotKind.sustenna => _sustennaContent(),
            DepotKind.trinza => _trinzaContent(),
            DepotKind.maintena => _maintenaContent(),
          },
        ),
      ),
    );
  }

  // ── Sustenna (PP1M) ────────────────────────────────────────────────

  List<Widget> _sustennaContent() {
    return <Widget>[
      _OverviewCard(
        generic: sustenna.genericName,
        active: sustenna.activeSubstance,
        indication: sustenna.indication,
        interval: sustenna.injectionInterval,
      ),
      const SizedBox(height: 16),
      const _SectionHeader('AVAILABLE STRENGTHS'),
      const SizedBox(height: 8),
      _StrengthsTable(strengths: sustenna.availableStrengths),

      const SizedBox(height: 20),
      const _SectionHeader('ORAL PRE-TREATMENT'),
      const SizedBox(height: 8),
      _BodyCard(text: sustenna.oralPreTreatment),

      const SizedBox(height: 20),
      const _SectionHeader('INITIATION'),
      const SizedBox(height: 8),
      _InitiationStepsCard(steps: sustenna.initiationSteps),

      const SizedBox(height: 20),
      const _SectionHeader('MAINTENANCE'),
      const SizedBox(height: 8),
      _MaintenanceCard(
        range: sustenna.maintenanceDoseRange,
        unit: sustenna.maintenanceUnit,
        window: sustenna.maintenanceWindow,
      ),

      const SizedBox(height: 20),
      const _SectionHeader('NEEDLE GUIDE'),
      const SizedBox(height: 8),
      _NeedleGuideTable(guides: sustenna.needleGuide),
      const SizedBox(height: 8),
      _BodyCard(text: sustenna.injectionSiteNote),

      const SizedBox(height: 20),
      const _SectionHeader('MISSED DOSE · INITIATION'),
      const SizedBox(height: 8),
      _MissedDoseList(scenarios: sustenna.missedDoseInitiation),

      const SizedBox(height: 20),
      const _SectionHeader('MISSED DOSE · MAINTENANCE'),
      const SizedBox(height: 8),
      _MissedDoseList(scenarios: sustenna.missedDoseMaintenance),

      const SizedBox(height: 20),
      const _SectionHeader('RENAL ADJUSTMENT'),
      const SizedBox(height: 8),
      _PaliperidoneRenalTable(rows: sustenna.renalAdjustments),

      const SizedBox(height: 20),
      const _SectionHeader('KEY WARNINGS'),
      const SizedBox(height: 8),
      _BulletCard(items: sustenna.keyWarnings, tone: AppColors.warning),

      const SizedBox(height: 20),
      _CitationsList(citations: sustenna.citations),
    ];
  }

  // ── Trinza (PP3M) ──────────────────────────────────────────────────

  List<Widget> _trinzaContent() {
    return <Widget>[
      _OverviewCard(
        generic: trinza.genericName,
        active: trinza.activeSubstance,
        indication: trinza.indication,
        interval: trinza.injectionInterval,
      ),
      const SizedBox(height: 16),
      const _SectionHeader('AVAILABLE STRENGTHS'),
      const SizedBox(height: 8),
      _StrengthsTable(strengths: trinza.availableStrengths),

      const SizedBox(height: 20),
      const _SectionHeader('ELIGIBILITY'),
      const SizedBox(height: 8),
      _BulletCard(items: trinza.eligibilityCriteria, tone: AppColors.danger),

      const SizedBox(height: 20),
      const _SectionHeader('PP1M → PP3M CONVERSION'),
      const SizedBox(height: 8),
      _ConversionTable(
        rows: trinza.pp1mToTrinzaConversion
            .map((r) => (r.pp1mMgEq, r.pp3mMgEq))
            .toList(),
        leftHeader: 'PP1M (mg eq)',
        rightHeader: 'PP3M (mg eq)',
      ),
      const SizedBox(height: 8),
      _BodyCard(text: trinza.firstDoseTiming),

      const SizedBox(height: 20),
      const _SectionHeader('MAINTENANCE'),
      const SizedBox(height: 8),
      _MaintenanceCard(
        range: trinza.maintenanceDoseRange,
        unit: trinza.maintenanceUnit,
        window: trinza.maintenanceWindow,
      ),

      const SizedBox(height: 20),
      const _SectionHeader('NEEDLE GUIDE'),
      const SizedBox(height: 8),
      _NeedleGuideTable(guides: trinza.needleGuide),
      const SizedBox(height: 8),
      _BodyCard(text: trinza.injectionSiteNote),

      const SizedBox(height: 20),
      const _SectionHeader('MISSED DOSE'),
      const SizedBox(height: 8),
      _MissedDoseList(scenarios: trinza.missedDoseScenarios),

      const SizedBox(height: 20),
      const _SectionHeader('PP1M BRIDGE TABLE'),
      const SizedBox(height: 8),
      _ConversionTable(
        rows: trinza.pp1mBridgeTable
            .map((r) => (r.pp3mStrengthMgEq, r.pp1mBridgeMgEq))
            .toList(),
        leftHeader: 'PP3M last dose',
        rightHeader: 'PP1M bridge',
      ),

      const SizedBox(height: 20),
      const _SectionHeader('RENAL ADJUSTMENT'),
      const SizedBox(height: 8),
      ...trinza.renalAdjustments.map(
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LabelledNoteCard(
            label: r.category,
            sublabel: r.crcl,
            body: r.notes,
          ),
        ),
      ),

      const SizedBox(height: 12),
      const _SectionHeader('PK NOTES'),
      const SizedBox(height: 8),
      _BulletCard(items: trinza.pkNotes, tone: AppColors.muted),

      const SizedBox(height: 20),
      const _SectionHeader('KEY WARNINGS'),
      const SizedBox(height: 8),
      _BulletCard(items: trinza.keyWarnings, tone: AppColors.warning),

      const SizedBox(height: 20),
      _CitationsList(citations: trinza.citations),
    ];
  }

  // ── Maintena ───────────────────────────────────────────────────────

  List<Widget> _maintenaContent() {
    return <Widget>[
      _OverviewCard(
        generic: maintena.genericName,
        active: maintena.activeSubstance,
        indication: maintena.indication,
        interval: maintena.injectionInterval,
      ),
      const SizedBox(height: 16),
      const _SectionHeader('AVAILABLE STRENGTHS'),
      const SizedBox(height: 8),
      _MaintenaStrengthsCard(strengths: maintena.availableStrengths),

      const SizedBox(height: 20),
      const _SectionHeader('ORAL PRE-TREATMENT'),
      const SizedBox(height: 8),
      _BodyCard(text: maintena.oralPreTreatment),

      const SizedBox(height: 20),
      const _SectionHeader('INITIATION METHODS'),
      const SizedBox(height: 8),
      _MaintenaMethodCard(method: maintena.initiationMethods.fourteenDay),
      const SizedBox(height: 8),
      _MaintenaMethodCard(method: maintena.initiationMethods.oneDay),
      const SizedBox(height: 12),
      _InitiationStepsCard(steps: maintena.initiationSteps),

      const SizedBox(height: 20),
      const _SectionHeader('MAINTENANCE'),
      const SizedBox(height: 8),
      _MaintenanceCard(
        range: maintena.maintenanceDoseRange,
        unit: maintena.maintenanceUnit,
        window: maintena.maintenanceWindow,
      ),

      const SizedBox(height: 20),
      const _SectionHeader('NEEDLE GUIDE'),
      const SizedBox(height: 8),
      _NeedleGuideTable(guides: maintena.needleGuide),
      const SizedBox(height: 8),
      _BodyCard(text: maintena.injectionSiteNote),

      const SizedBox(height: 20),
      const _SectionHeader('MISSED DOSE · 2nd OR 3rd'),
      const SizedBox(height: 8),
      _MissedDoseList(scenarios: maintena.missedDoseSecondThird),

      const SizedBox(height: 20),
      const _SectionHeader('MISSED DOSE · 4th ONWARD'),
      const SizedBox(height: 8),
      _MissedDoseList(scenarios: maintena.missedDoseFourthOnward),

      const SizedBox(height: 20),
      const _SectionHeader('DRUG INTERACTIONS'),
      const SizedBox(height: 8),
      ...maintena.drugInteractions.map(
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DepotInteractionCard(adjustment: i),
        ),
      ),

      const SizedBox(height: 12),
      const _SectionHeader('ORGAN FUNCTION'),
      const SizedBox(height: 8),
      _LabelledNoteCard(
        label: 'Renal',
        sublabel: '',
        body: maintena.renalNote,
      ),
      const SizedBox(height: 8),
      _LabelledNoteCard(
        label: 'Hepatic',
        sublabel: '',
        body: maintena.hepaticNote,
      ),

      const SizedBox(height: 16),
      const _SectionHeader('PK NOTES'),
      const SizedBox(height: 8),
      _BulletCard(items: maintena.pkNotes, tone: AppColors.muted),

      const SizedBox(height: 20),
      const _SectionHeader('KEY WARNINGS'),
      const SizedBox(height: 8),
      _BulletCard(items: maintena.keyWarnings, tone: AppColors.warning),

      const SizedBox(height: 20),
      _CitationsList(citations: maintena.citations),
    ];
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextSizes.eyebrow);
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.generic,
    required this.active,
    required this.indication,
    required this.interval,
  });

  final String generic;
  final String active;
  final String indication;
  final String interval;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            generic,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Active: $active',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            indication,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              interval,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          height: 1.55,
        ),
      ),
    );
  }
}

class _StrengthsTable extends StatelessWidget {
  const _StrengthsTable({required this.strengths});

  final List<StrengthEntry> strengths;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          const _StrengthRow(
            mgEq: 'mg eq',
            mgPP: 'mg PP',
            volume: 'mL',
            isHeader: true,
          ),
          const Divider(height: 1, color: AppColors.border),
          ...strengths.map(
            (s) => Column(
              children: <Widget>[
                _StrengthRow(
                  mgEq: s.mgEq.toString(),
                  mgPP: s.mgPP.toString(),
                  volume: s.volumeMl.toString(),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthRow extends StatelessWidget {
  const _StrengthRow({
    required this.mgEq,
    required this.mgPP,
    required this.volume,
    this.isHeader = false,
  });

  final String mgEq;
  final String mgPP;
  final String volume;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isHeader ? AppColors.muted : AppColors.text,
      fontSize: isHeader ? 11 : 13,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: isHeader ? 1.3 : 0,
      fontFamily: isHeader ? null : 'monospace',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(isHeader ? mgEq.toUpperCase() : mgEq, style: style)),
          Expanded(child: Text(isHeader ? mgPP.toUpperCase() : mgPP, style: style)),
          Expanded(child: Text(isHeader ? volume.toUpperCase() : volume, style: style)),
        ],
      ),
    );
  }
}

class _MaintenaStrengthsCard extends StatelessWidget {
  const _MaintenaStrengthsCard({required this.strengths});

  final List<MaintenaStrengthEntry> strengths;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: strengths.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 80,
                  child: Text(
                    '${s.mgAripiprazole.toInt()} mg',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.formulation,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InitiationStepsCard extends StatelessWidget {
  const _InitiationStepsCard({required this.steps});

  final List<DepotInitiationStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                      s.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.doseMgEq} mg',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Site: ${s.site}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (s.notes != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    s.notes!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.range,
    required this.unit,
    required this.window,
  });

  final MaintenanceDoseRange range;
  final String unit;
  final String window;

  @override
  Widget build(BuildContext context) {
    final recommended = range.recommended;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '${range.min}–${range.max}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (recommended != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Recommended: $recommended $unit',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Window: $window',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedleGuideTable extends StatelessWidget {
  const _NeedleGuideTable({required this.guides});

  final List<NeedleGuide> guides;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          const _NeedleRow(
            site: 'Site',
            habitus: 'Habitus',
            gauge: 'Gauge',
            length: 'Length',
            isHeader: true,
          ),
          const Divider(height: 1, color: AppColors.border),
          ...guides.map(
            (g) => Column(
              children: <Widget>[
                _NeedleRow(
                  site: g.site,
                  habitus: g.habitus,
                  gauge: g.gauge,
                  length: g.lengthInch,
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedleRow extends StatelessWidget {
  const _NeedleRow({
    required this.site,
    required this.habitus,
    required this.gauge,
    required this.length,
    this.isHeader = false,
  });

  final String site;
  final String habitus;
  final String gauge;
  final String length;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isHeader ? AppColors.muted : AppColors.text,
      fontSize: isHeader ? 11 : 12.5,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: isHeader ? 1.3 : 0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(isHeader ? site.toUpperCase() : site, style: style),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isHeader ? habitus.toUpperCase() : habitus,
              style: style,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              isHeader ? gauge.toUpperCase() : gauge,
              style: style,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isHeader ? length.toUpperCase() : length,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedDoseList extends StatelessWidget {
  const _MissedDoseList({required this.scenarios});

  final List<MissedDoseScenario> scenarios;

  Color _color(DepotSeverity s) => switch (s) {
        DepotSeverity.info => AppColors.to,
        DepotSeverity.warning => AppColors.warning,
        DepotSeverity.danger => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: scenarios.map((s) {
        final c = _color(s.severity);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.06),
              border: Border(left: BorderSide(color: c, width: 3)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.condition,
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.action,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PaliperidoneRenalTable extends StatelessWidget {
  const _PaliperidoneRenalTable({required this.rows});

  final List<PaliperidoneRenalAdjustment> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((r) {
        final isContra = r.day1 == 'CONTRAINDICATED';
        final tone = isContra ? AppColors.danger : AppColors.text;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: isContra
                    ? AppColors.danger.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        r.category,
                        style: TextStyle(
                          color: tone,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      r.crcl,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _RenalLine(label: 'Day 1', value: r.day1, isContra: isContra),
                _RenalLine(label: 'Day 8', value: r.day8, isContra: isContra),
                _RenalLine(
                    label: 'Maintenance', value: r.maintenance, isContra: isContra),
                _RenalLine(label: 'Max', value: r.max, isContra: isContra),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RenalLine extends StatelessWidget {
  const _RenalLine({
    required this.label,
    required this.value,
    required this.isContra,
  });

  final String label;
  final String value;
  final bool isContra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isContra ? AppColors.danger : AppColors.text,
                fontSize: 12.5,
                fontWeight:
                    isContra ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelledNoteCard extends StatelessWidget {
  const _LabelledNoteCard({
    required this.label,
    required this.sublabel,
    required this.body,
  });

  final String label;
  final String sublabel;
  final String body;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sublabel.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionTable extends StatelessWidget {
  const _ConversionTable({
    required this.rows,
    required this.leftHeader,
    required this.rightHeader,
  });

  final List<(num, num)> rows;
  final String leftHeader;
  final String rightHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    leftHeader.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rightHeader.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...rows.map(
            (r) => Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          r.$1.toString(),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.$2.toString(),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenaMethodCard extends StatelessWidget {
  const _MaintenaMethodCard({required this.method});

  final MaintenaInitiationMethod method;

  @override
  Widget build(BuildContext context) {
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
          Text(
            method.label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _LabelLine(label: 'Injection', body: method.injection),
          const SizedBox(height: 6),
          _LabelLine(label: 'Oral', body: method.oral),
          const SizedBox(height: 8),
          Text(
            method.notes,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
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

class _DepotInteractionCard extends StatelessWidget {
  const _DepotInteractionCard({required this.adjustment});

  final DrugInteractionAdjustment adjustment;

  Color _color(DepotSeverity s) => switch (s) {
        DepotSeverity.info => AppColors.to,
        DepotSeverity.warning => AppColors.warning,
        DepotSeverity.danger => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final c = _color(adjustment.severity);
    return Container(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: c, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            adjustment.situation,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            adjustment.action,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.items, required this.tone});

  final List<String> items;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.05),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s,
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
        const _SectionHeader('CITATIONS'),
        const SizedBox(height: 6),
        ...citations.map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $c',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
