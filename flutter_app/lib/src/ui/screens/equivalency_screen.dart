// Dose-equivalency calculator — three families on one screen.
// Rewritten 2026-05-23.
//
// Pick family → from-drug → enter dose → optional to-drug. The card
// surfaces both the reference-units expression and the converted
// dose. Three families:
//   • Antipsychotics    → CPZ-eq
//   • Antidepressants   → fluoxetine-eq
//   • Benzodiazepines   → diazepam-eq
//
// Architecture (top → bottom):
//   - EquivalencyScreen      Route widget; Scaffold + responsive body.
//   - _EquivalencyForm       Stateful body; family + drugs + dose.
//   - _FamilyTabs            Three-up segmented control with sub-labels.
//   - _FamilyMeta            Reference dose + short label inline.
//   - _DrugPicker            Bordered dropdown.
//   - _DoseInput             Numeric field with mg suffix.
//   - _ResultPanel           Accent-tinted equivalent + optional convert-to.
//   - _AwaitingResult        Pre-input guide card.
//   - _LimitationsCard       Bulleted limitations + sources.
//
// Motion: EntranceFade cascade on first paint (hero → tabs → meta →
// pickers → result), 60ms stagger.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/tool_hero.dart';
import 'package:psychswitch_engine/dose_equivalents.dart';

class EquivalencyScreen extends StatefulWidget {
  const EquivalencyScreen({super.key});

  @override
  State<EquivalencyScreen> createState() => _EquivalencyScreenState();
}

class _EquivalencyScreenState extends State<EquivalencyScreen> {
  EquivalencyFamily _family = EquivalencyFamily.cpz;
  String? _fromId;
  String? _toId;
  final _doseCtl = TextEditingController();

  static const _tabs = <_FamilyTab>[
    _FamilyTab(EquivalencyFamily.cpz, 'Antipsychotics', 'CPZ-eq'),
    _FamilyTab(EquivalencyFamily.fluoxetine, 'Antidepressants', 'FLX-eq'),
    _FamilyTab(EquivalencyFamily.diazepam, 'Benzodiazepines', 'DZP-eq'),
  ];

  @override
  void dispose() {
    _doseCtl.dispose();
    super.dispose();
  }

  void _setFamily(EquivalencyFamily f) {
    if (f == _family) return;
    setState(() {
      _family = f;
      _fromId = null;
      _toId = null;
      _doseCtl.clear();
    });
  }

  /// Display formatter — strips trailing zeroes on decimals.
  /// "100.0" → "100"; "12.50" → "12.5".
  String _fmt(num n) {
    if (n is int || n == n.toInt()) return n.toInt().toString();
    return n.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final meta = equivalencyFamilies[_family]!;
    final fromDose = double.tryParse(_doseCtl.text);
    final validDose = fromDose != null && fromDose > 0;

    final refResult = (validDose && _fromId != null)
        ? doseInReferenceUnits(_family, _fromId!, fromDose)
        : null;
    final convResult =
        (validDose && _fromId != null && _toId != null && _fromId != _toId)
            ? convertWithinFamily(_family, _fromId!, fromDose, _toId!)
            : null;

    final totalDrugs = equivalencyFamilies.values
        .fold<int>(0, (sum, m) => sum + m.entries.length);

    // ── Form column ────────────────────────────────────────────────
    final form = <Widget>[
      EntranceFade(
        child: ToolHero(
          icon: Icons.balance_outlined,
          title: 'Dose equivalency',
          tagline: 'Cross-class dose conversion',
          tone: ClinicalPalette.accent,
          stats: <ToolHeroStat>[
            ToolHeroStat(
              label: 'FAMILIES',
              value: '${_tabs.length}',
              unit: 'classes',
            ),
            ToolHeroStat(
              label: 'CATALOGUE',
              value: '$totalDrugs',
              unit: 'drugs',
            ),
          ],
          rationale: 'Convert a dose within a drug family against its '
              'reference standard — chlorpromazine, fluoxetine or '
              'diazepam equivalents. Pick a family, a from-drug and '
              'dose; add a to-drug to convert directly.',
        ),
      ),
      const Gap.v(ClinicalSpace.lg),
      EntranceFade(
        index: 1,
        child: _FamilyTabs(
          tabs: _tabs,
          selected: _family,
          onChanged: _setFamily,
        ),
      ),
      const Gap.v(ClinicalSpace.md),
      EntranceFade(
        index: 2,
        child: _FamilyMeta(meta: meta, fmt: _fmt),
      ),
      const Gap.v(ClinicalSpace.md),
      EntranceFade(
        index: 3,
        child: _PickerSection(
          eyebrow: 'FROM DRUG',
          picker: _DrugPicker(
            entries: meta.entries,
            selectedId: _fromId,
            onChanged: (id) => setState(() => _fromId = id),
          ),
          input: _DoseInput(
            controller: _doseCtl,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
      const Gap.v(ClinicalSpace.lg),
      EntranceFade(
        index: 4,
        child: _PickerSection(
          eyebrow: 'CONVERT TO (OPTIONAL)',
          picker: _DrugPicker(
            entries: meta.entries.where((e) => e.id != _fromId).toList(),
            selectedId: _toId,
            onChanged: (id) => setState(() => _toId = id),
            hint: 'Pick a target drug',
          ),
        ),
      ),
    ];

    // ── Output column ──────────────────────────────────────────────
    final output = <Widget>[
      EntranceFade(
        index: 5,
        child: refResult != null
            ? _ResultPanel(
                meta: meta,
                fromName: meta.entries
                    .firstWhere((e) => e.id == _fromId)
                    .genericName,
                fromDoseMg: fromDose!,
                refUnits: refResult.refUnits,
                referenceDoseMg: refResult.referenceDoseMg,
                conv: convResult == null
                    ? null
                    : (
                        toName: meta.entries
                            .firstWhere((e) => e.id == _toId)
                            .genericName,
                        toDoseMg: convResult.toDoseMg,
                      ),
                fmt: _fmt,
              )
            : const _AwaitingResult(),
      ),
      const Gap.v(ClinicalSpace.lg),
      EntranceFade(
        index: 6,
        child: _LimitationsCard(meta: meta),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose equivalency'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: context.isWide
            ? _WideLayout(form: form, output: output)
            : _NarrowLayout(children: <Widget>[...form, ...output]),
      ),
    );
  }
}

// ── Layout shells ───────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.form, required this.output});

  final List<Widget> form;
  final List<Widget> output;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.lg,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: form,
              ),
            ),
          ),
          const Gap.h(ClinicalSpace.xl),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: output,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.lg,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }
}

// ── Family tabs ─────────────────────────────────────────────────────

/// Immutable tab record — keeps the tabs list a declarative constant.
class _FamilyTab {
  const _FamilyTab(this.family, this.label, this.shortLabel);
  final EquivalencyFamily family;
  final String label;
  final String shortLabel;
}

/// Three-up segmented control with a stretched accent fill on the
/// active tab. The AnimatedContainer carries the active-tone change
/// across taps — feels like a slider, reads like a tab.
class _FamilyTabs extends StatelessWidget {
  const _FamilyTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<_FamilyTab> tabs;
  final EquivalencyFamily selected;
  final ValueChanged<EquivalencyFamily> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          for (final tab in tabs)
            Expanded(
              child: _FamilyTabCell(
                tab: tab,
                isActive: tab.family == selected,
                onTap: () => onChanged(tab.family),
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilyTabCell extends StatelessWidget {
  const _FamilyTabCell({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _FamilyTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: '${tab.label}, ${tab.shortLabel}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(vertical: ClinicalSpace.sm + 2),
          decoration: BoxDecoration(
            color: isActive ? ClinicalPalette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(ClinicalRadii.chip),
          ),
          child: Column(
            children: <Widget>[
              Text(
                tab.label,
                style: TextStyle(
                  color: isActive ? Colors.white : ClinicalPalette.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap.v(2),
              Text(
                tab.shortLabel,
                style: TextStyle(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.85)
                      : ClinicalPalette.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Family meta ─────────────────────────────────────────────────────

/// Compact strip naming the current family + its reference standard
/// (e.g. "Chlorpromazine 100 mg = 1 CPZ-eq"). Sits below the tabs
/// so the unit of conversion is always visible.
class _FamilyMeta extends StatelessWidget {
  const _FamilyMeta({required this.meta, required this.fmt});

  final EquivalencyFamilyMeta meta;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(meta.title, style: ClinicalText.eyebrow),
        const Gap.v(2),
        Text(
          'Reference: ${meta.reference.name} ${fmt(meta.reference.mg)} mg = '
          '1 ${meta.shortLabel}',
          style: ClinicalText.caption.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

// ── Picker section ──────────────────────────────────────────────────

/// Eyebrow + dropdown + optional dose input. Composes the FROM / TO
/// sections without each repeating the labelled-section chrome.
class _PickerSection extends StatelessWidget {
  const _PickerSection({
    required this.eyebrow,
    required this.picker,
    this.input,
  });

  final String eyebrow;
  final Widget picker;
  final Widget? input;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(eyebrow, style: ClinicalText.eyebrow),
        const Gap.v(ClinicalSpace.sm),
        picker,
        if (input != null) ...<Widget>[
          const Gap.v(ClinicalSpace.md),
          input!,
        ],
      ],
    );
  }
}

// ── Drug picker ─────────────────────────────────────────────────────

class _DrugPicker extends StatelessWidget {
  const _DrugPicker({
    required this.entries,
    required this.selectedId,
    required this.onChanged,
    this.hint = 'Pick a drug',
  });

  final List<EquivalencyEntry> entries;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String?>(
            value: selectedId,
            isExpanded: true,
            dropdownColor: ClinicalPalette.surface,
            iconEnabledColor: ClinicalPalette.muted,
            hint: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.md,
              ),
              child: Text(
                hint,
                style: const TextStyle(
                  color: ClinicalPalette.muted,
                  fontSize: 14,
                ),
              ),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: ClinicalSpace.md),
                  child: Text(
                    '— none —',
                    style: TextStyle(
                      color: ClinicalPalette.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              for (final e in entries)
                DropdownMenuItem<String?>(
                  value: e.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClinicalSpace.md,
                    ),
                    child: Text(
                      e.genericName,
                      style: const TextStyle(
                        color: ClinicalPalette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ── Dose input ──────────────────────────────────────────────────────

class _DoseInput extends StatelessWidget {
  const _DoseInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Current dose (mg)',
        suffixText: 'mg',
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

// ── Result panel ────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.meta,
    required this.fromName,
    required this.fromDoseMg,
    required this.refUnits,
    required this.referenceDoseMg,
    required this.conv,
    required this.fmt,
  });

  final EquivalencyFamilyMeta meta;
  final String fromName;
  final num fromDoseMg;
  final num refUnits;
  final num referenceDoseMg;
  final ({String toName, num toDoseMg})? conv;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.accent.withValues(alpha: 0.06),
        border: Border.all(
          color: ClinicalPalette.accent.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
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
          const Text('EQUIVALENT DOSE', style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.xs + 2),
          Text(
            '$fromName ${fmt(fromDoseMg)} mg',
            style: const TextStyle(
              color: ClinicalPalette.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const Gap.v(ClinicalSpace.xs),
          Text(
            '≈ ${fmt(refUnits)} ${meta.shortLabel} '
            '(${fmt(referenceDoseMg)} mg ${meta.reference.name})',
            style: const TextStyle(
              color: ClinicalPalette.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (conv != null) ...<Widget>[
            const Gap.v(ClinicalSpace.md),
            const Divider(height: 1),
            const Gap.v(ClinicalSpace.md),
            const Text('CONVERTS TO', style: ClinicalText.eyebrow),
            const Gap.v(ClinicalSpace.xs + 2),
            Text(
              '${conv!.toName} ${fmt(conv!.toDoseMg)} mg',
              style: const TextStyle(
                color: ClinicalPalette.toneMintInk,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Awaiting-result guide card ──────────────────────────────────────

/// Pre-input placeholder shown in the output column before a from-drug
/// and dose are entered — so the result area guides the clinician
/// rather than sitting blank. NOT the shared EmptyState primitive
/// (which is centered + dramatic); this is a quiet left-aligned guide.
class _AwaitingResult extends StatelessWidget {
  const _AwaitingResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.balance_outlined,
            color: ClinicalPalette.muted,
            size: 26,
          ),
          Gap.v(ClinicalSpace.md),
          Text(
            'Equivalent dose appears here',
            style: TextStyle(
              color: ClinicalPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          Gap.v(ClinicalSpace.xs),
          _AwaitingBody(),
        ],
      ),
    );
  }
}

class _AwaitingBody extends StatelessWidget {
  const _AwaitingBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Pick a from-drug and enter a dose. Add an optional to-drug to '
      'convert directly between two agents.',
      style: ClinicalText.caption.copyWith(height: 1.5),
    );
  }
}

// ── Limitations card ────────────────────────────────────────────────

class _LimitationsCard extends StatelessWidget {
  const _LimitationsCard({required this.meta});

  final EquivalencyFamilyMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
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
          const Text('LIMITATIONS', style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.xs),
          for (final l in meta.limitations)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $l',
                style: ClinicalText.caption.copyWith(height: 1.5),
              ),
            ),
          const Gap.v(ClinicalSpace.sm),
          const Text('SOURCES', style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.xs),
          for (final c in meta.citations)
            Text(
              '· $c',
              style: ClinicalText.caption.copyWith(fontFamily: 'monospace'),
            ),
        ],
      ),
    );
  }
}
