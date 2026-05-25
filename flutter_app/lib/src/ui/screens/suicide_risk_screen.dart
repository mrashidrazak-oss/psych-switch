// Suicide risk assessment screen.
//
// The most consequential clinical surface in the app. Composes
// C-SSRS ideation + behaviour with a static-and-dynamic risk factor
// inventory and a protective factor inventory; the engine returns a
// composite tier (acute / high / moderate / low / minimal), a
// disposition string, and a paste-ready clinical note.
//
// DECISION SUPPORT, NOT A DECISION. The acute-tier output mandates
// direct ED transfer; the moderate and low tiers mandate safety plan
// + follow-up. The screen names the disposition in plain language but
// always defers to the clinician for actual care decisions.
//
// Architecture (top → bottom):
//   - SuicideRiskScreen   Route widget; Scaffold + body.
//   - _RiskBody           Stateful body; owns CSSRS + factor inputs.
//   - _IdeationStep       5-level CSSRS ladder + "last month" toggle.
//   - _BehaviourStep      Two booleans (lifetime / last 3 months).
//   - _RiskFactors        Grouped static + dynamic checkboxes.
//   - _ProtectiveFactors  Checkboxes for protective factors.
//   - _Verdict            Composite tier + disposition + rationale.
//   - _NoteSection        Paste-ready clinical note + copy action.
//   - _SectionCard        Bordered card with eyebrow + body.
//   - _FactorRow          One checkbox with title + clinical note.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch/src/ui/widgets/tool_hero.dart';
import 'package:psychswitch_engine/cssrs.dart';
import 'package:psychswitch_engine/suicide_risk.dart';

class SuicideRiskScreen extends StatefulWidget {
  const SuicideRiskScreen({super.key});

  @override
  State<SuicideRiskScreen> createState() => _SuicideRiskScreenState();
}

class _SuicideRiskScreenState extends State<SuicideRiskScreen> {
  int _ideationLevel = 0;
  bool _ideationLastMonth = false;
  bool _behaviourLifetime = false;
  bool _behaviourLast3Months = false;
  final Set<SuicideRiskFactor> _risk = <SuicideRiskFactor>{};
  final Set<SuicideProtectiveFactor> _protective =
      <SuicideProtectiveFactor>{};

  bool get _hasAny =>
      _ideationLevel > 0 ||
      _ideationLastMonth ||
      _behaviourLifetime ||
      _behaviourLast3Months ||
      _risk.isNotEmpty ||
      _protective.isNotEmpty;

  void _reset() {
    unawaited(hapticsTap());
    setState(() {
      _ideationLevel = 0;
      _ideationLastMonth = false;
      _behaviourLifetime = false;
      _behaviourLast3Months = false;
      _risk.clear();
      _protective.clear();
    });
  }

  void _setIdeation(int level) {
    unawaited(hapticsTap());
    setState(() {
      _ideationLevel = level;
      if (level == 0) _ideationLastMonth = false;
    });
  }

  void _toggleIdeationMonth() {
    unawaited(hapticsTap());
    setState(() => _ideationLastMonth = !_ideationLastMonth);
  }

  void _toggleBehaviourLifetime() {
    unawaited(hapticsTap());
    setState(() {
      _behaviourLifetime = !_behaviourLifetime;
      if (!_behaviourLifetime) _behaviourLast3Months = false;
    });
  }

  void _toggleBehaviourRecent() {
    unawaited(hapticsTap());
    setState(() {
      _behaviourLast3Months = !_behaviourLast3Months;
      if (_behaviourLast3Months) _behaviourLifetime = true;
    });
  }

  void _toggleRisk(SuicideRiskFactor f) {
    unawaited(hapticsTap());
    setState(() {
      if (_risk.contains(f)) {
        _risk.remove(f);
      } else {
        _risk.add(f);
      }
    });
  }

  void _toggleProtective(SuicideProtectiveFactor f) {
    unawaited(hapticsTap());
    setState(() {
      if (_protective.contains(f)) {
        _protective.remove(f);
      } else {
        _protective.add(f);
      }
    });
  }

  Future<void> _copyNote(SuicideRiskAssessment assessment) async {
    await Clipboard.setData(ClipboardData(text: assessment.clinicalNote()));
    if (!mounted) return;
    showCopiedToast(context, label: 'Risk assessment note');
  }

  @override
  Widget build(BuildContext context) {
    final input = SuicideRiskInput(
      cssrs: CssrsInput(
        highestIdeationLevel: _ideationLevel,
        ideationLastMonth: _ideationLastMonth,
        behaviourLifetime: _behaviourLifetime,
        behaviourLast3Months: _behaviourLast3Months,
      ),
      riskFactors: _risk,
      protectiveFactors: _protective,
    );
    final assessment = assessSuicideRisk(input);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suicide risk assessment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_hasAny)
            IconButton(
              tooltip: 'Reset',
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
            ),
          const Gap.h(ClinicalSpace.xs),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg + 4,
            ClinicalSpace.lg,
            ClinicalSpace.lg + 4,
            ClinicalSpace.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            EntranceFade(child: _hero()),
            const Gap.v(ClinicalSpace.lg),
            EntranceFade(
              index: 1,
              child: _Verdict(assessment: assessment, hasAny: _hasAny),
            ),
            const Gap.v(ClinicalSpace.lg),
            EntranceFade(
              index: 2,
              child: _SectionCard(
                eyebrow: '1 — IDEATION (C-SSRS)',
                child: _IdeationStep(
                  level: _ideationLevel,
                  ideationLastMonth: _ideationLastMonth,
                  onSetLevel: _setIdeation,
                  onToggleMonth: _toggleIdeationMonth,
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.lg),
            EntranceFade(
              index: 3,
              child: _SectionCard(
                eyebrow: '2 — BEHAVIOUR (C-SSRS)',
                child: _BehaviourStep(
                  lifetime: _behaviourLifetime,
                  last3Months: _behaviourLast3Months,
                  onToggleLifetime: _toggleBehaviourLifetime,
                  onToggleRecent: _toggleBehaviourRecent,
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.lg),
            EntranceFade(
              index: 4,
              child: _SectionCard(
                eyebrow: '3 — RISK FACTORS',
                child: _RiskFactors(
                  selected: _risk,
                  onToggle: _toggleRisk,
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.lg),
            EntranceFade(
              index: 5,
              child: _SectionCard(
                eyebrow: '4 — PROTECTIVE FACTORS',
                child: _ProtectiveFactors(
                  selected: _protective,
                  onToggle: _toggleProtective,
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.lg),
            EntranceFade(
              index: 6,
              child: _NoteSection(
                assessment: assessment,
                onCopy: () => _copyNote(assessment),
              ),
            ),
            const Gap.v(ClinicalSpace.lg),
            const EntranceFade(index: 7, child: _Disclaimer()),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return const ToolHero(
      icon: Icons.emergency_outlined,
      title: 'Suicide risk assessment',
      tagline: 'Composite tier + disposition',
      tone: ClinicalPalette.danger,
      stats: <ToolHeroStat>[
        ToolHeroStat(
          label: 'C-SSRS',
          value: '5',
          unit: 'ideation levels',
        ),
        ToolHeroStat(
          label: 'FACTORS',
          value: '22',
          unit: 'risk + protective',
        ),
      ],
      rationale: 'Walks the Columbia ladder, captures risk + protective '
          'factors, returns a composite tier with disposition and a '
          'paste-ready note. Decision support — never a substitute '
          'for clinical interview.',
    );
  }
}

// ── Section card ────────────────────────────────────────────────────

/// Bordered card with an eyebrow header and a body slot. Used for
/// each of the four input sections (ideation, behaviour, risk,
/// protective) so they all share the same visual rhythm.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

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
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow, style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.md),
          child,
        ],
      ),
    );
  }
}

// ── Ideation step ───────────────────────────────────────────────────

/// 5-level C-SSRS ladder. Each level is an InkWell row with the
/// prompt + note; tapping toggles the highest-reached level. The
/// "in the last month" toggle activates only when a level is picked.
class _IdeationStep extends StatelessWidget {
  const _IdeationStep({
    required this.level,
    required this.ideationLastMonth,
    required this.onSetLevel,
    required this.onToggleMonth,
  });

  final int level;
  final bool ideationLastMonth;
  final ValueChanged<int> onSetLevel;
  final VoidCallback onToggleMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Highest level reached. Tap a level to toggle; tap again '
          'to clear back to none.',
          style: ClinicalText.caption.copyWith(height: 1.5),
        ),
        const Gap.v(ClinicalSpace.sm + 2),
        for (final item in kCssrsIdeationLadder)
          _LadderRow(
            item: item,
            selected: level == item.level,
            anyHigher: level > item.level,
            onTap: () => onSetLevel(level == item.level ? 0 : item.level),
          ),
        const Gap.v(ClinicalSpace.md),
        _CheckRow(
          label: 'Ideation present in the last month',
          subtitle: 'Required for moderate-tier triage at level 2 or '
              'higher.',
          checked: ideationLastMonth,
          enabled: level > 0,
          onToggle: onToggleMonth,
        ),
      ],
    );
  }
}

/// Single ladder row. Selected level is danger-tinted; lower levels
/// stay muted; higher levels are subtly highlighted as "also true".
class _LadderRow extends StatelessWidget {
  const _LadderRow({
    required this.item,
    required this.selected,
    required this.anyHigher,
    required this.onTap,
  });

  final CssrsItem item;
  final bool selected;
  final bool anyHigher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? ClinicalPalette.danger
        : (anyHigher
            ? ClinicalPalette.mutedStrong
            : ClinicalPalette.text);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.xs + 2,
          vertical: ClinicalSpace.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? ClinicalPalette.danger
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? ClinicalPalette.danger
                      : ClinicalPalette.borderStrong,
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${item.level}',
                style: TextStyle(
                  color: selected ? Colors.white : ClinicalPalette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Gap.h(ClinicalSpace.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.prompt,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const Gap.v(2),
                  Text(
                    item.note,
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

// ── Behaviour step ──────────────────────────────────────────────────

class _BehaviourStep extends StatelessWidget {
  const _BehaviourStep({
    required this.lifetime,
    required this.last3Months,
    required this.onToggleLifetime,
    required this.onToggleRecent,
  });

  final bool lifetime;
  final bool last3Months;
  final VoidCallback onToggleLifetime;
  final VoidCallback onToggleRecent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Actual / interrupted / aborted attempts AND preparatory '
          'acts all count.',
          style: ClinicalText.caption.copyWith(height: 1.5),
        ),
        const Gap.v(ClinicalSpace.sm + 2),
        _CheckRow(
          label: 'Any behaviour, lifetime',
          subtitle:
              'Includes preparatory acts, interrupted/aborted, and '
              'actual attempts at any point in life.',
          checked: lifetime,
          onToggle: onToggleLifetime,
        ),
        const Gap.v(ClinicalSpace.sm),
        _CheckRow(
          label: 'Any behaviour in the last 3 months',
          subtitle: 'Auto-implies lifetime. Promotes the C-SSRS tier '
              'to high — recent behaviour is the strongest near-term '
              'predictor.',
          checked: last3Months,
          enabled: lifetime,
          onToggle: onToggleRecent,
        ),
      ],
    );
  }
}

// ── Risk factors ────────────────────────────────────────────────────

/// Risk-factor checklist split into static (history) and dynamic
/// (current modifiable state). Each row is a _FactorRow with the
/// engine's note as helper text.
class _RiskFactors extends StatelessWidget {
  const _RiskFactors({required this.selected, required this.onToggle});

  final Set<SuicideRiskFactor> selected;
  final ValueChanged<SuicideRiskFactor> onToggle;

  @override
  Widget build(BuildContext context) {
    const all = SuicideRiskFactor.values;
    final staticFactors = all.where(isStaticRiskFactor).toList();
    final dynamicFactors = all.where((f) => !isStaticRiskFactor(f)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Subhead(text: 'STATIC (HISTORY)'),
        const Gap.v(ClinicalSpace.xs + 2),
        for (final f in staticFactors)
          _FactorRow(
            label: suicideRiskFactorLabel(f),
            note: suicideRiskFactorNote(f),
            checked: selected.contains(f),
            tone: ClinicalPalette.danger,
            onToggle: () => onToggle(f),
            isAmplifier: f.isAcuteAmplifier,
          ),
        const Gap.v(ClinicalSpace.md),
        const _Subhead(text: 'DYNAMIC (CURRENT)'),
        const Gap.v(ClinicalSpace.xs + 2),
        for (final f in dynamicFactors)
          _FactorRow(
            label: suicideRiskFactorLabel(f),
            note: suicideRiskFactorNote(f),
            checked: selected.contains(f),
            tone: ClinicalPalette.danger,
            onToggle: () => onToggle(f),
            isAmplifier: f.isAcuteAmplifier,
          ),
      ],
    );
  }
}

// ── Protective factors ──────────────────────────────────────────────

class _ProtectiveFactors extends StatelessWidget {
  const _ProtectiveFactors({
    required this.selected,
    required this.onToggle,
  });

  final Set<SuicideProtectiveFactor> selected;
  final ValueChanged<SuicideProtectiveFactor> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final f in SuicideProtectiveFactor.values)
          _FactorRow(
            label: suicideProtectiveFactorLabel(f),
            note: suicideProtectiveFactorNote(f),
            checked: selected.contains(f),
            tone: ClinicalPalette.toneMintInk,
            onToggle: () => onToggle(f),
          ),
      ],
    );
  }
}

class _Subhead extends StatelessWidget {
  const _Subhead({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ClinicalPalette.muted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

// ── Factor row + check row primitives ──────────────────────────────

/// Single checkbox row with a tinted check, a label, a one-line
/// clinical note underneath, and (optionally) an "ACUTE AMPLIFIER"
/// pill when the factor escalates risk to the acute tier.
class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.label,
    required this.note,
    required this.checked,
    required this.tone,
    required this.onToggle,
    this.isAmplifier = false,
  });

  final String label;
  final String note;
  final bool checked;
  final Color tone;
  final VoidCallback onToggle;
  final bool isAmplifier;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.xs,
          vertical: ClinicalSpace.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? tone : Colors.transparent,
                border: Border.all(
                  color: checked ? tone : ClinicalPalette.borderStrong,
                ),
                borderRadius: BorderRadius.circular(ClinicalRadii.chip),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: ClinicalPalette.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (isAmplifier) const _AmplifierPill(),
                    ],
                  ),
                  const Gap.v(2),
                  Text(
                    note,
                    style: ClinicalText.caption.copyWith(height: 1.45),
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

class _AmplifierPill extends StatelessWidget {
  const _AmplifierPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ClinicalPalette.danger.withValues(alpha: 0.12),
        border: Border.all(
          color: ClinicalPalette.danger.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      ),
      child: const Text(
        'ACUTE',
        style: TextStyle(
          color: ClinicalPalette.danger,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Generic checkbox row used by the C-SSRS sub-toggles (ideation in
/// last month, behaviour lifetime, behaviour last 3 months).
/// Distinct from _FactorRow which is for risk/protective factors with
/// engine-driven notes + amplifier pills.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.subtitle,
    required this.checked,
    required this.onToggle,
    this.enabled = true,
  });

  final String label;
  final String subtitle;
  final bool checked;
  final VoidCallback onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tone = enabled ? ClinicalPalette.danger : ClinicalPalette.muted;
    return InkWell(
      onTap: enabled ? onToggle : null,
      borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.xs,
          vertical: ClinicalSpace.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? tone : Colors.transparent,
                border: Border.all(
                  color: checked ? tone : ClinicalPalette.borderStrong,
                ),
                borderRadius: BorderRadius.circular(ClinicalRadii.chip),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? ClinicalPalette.text
                          : ClinicalPalette.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const Gap.v(2),
                  Text(
                    subtitle,
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

// ── Verdict ─────────────────────────────────────────────────────────

/// The composite tier card. Tone-codes by tier (danger for acute/high,
/// warning for moderate, accent for low, muted for minimal). Shows the
/// tier label as the headline, the disposition as the action line, and
/// the rationale as the why.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.assessment, required this.hasAny});

  final SuicideRiskAssessment assessment;
  final bool hasAny;

  Color get _tone {
    switch (assessment.tier) {
      case SuicideRiskTier.acute:
      case SuicideRiskTier.high:
        return ClinicalPalette.danger;
      case SuicideRiskTier.moderate:
        return ClinicalPalette.warning;
      case SuicideRiskTier.low:
        return ClinicalPalette.accent;
      case SuicideRiskTier.minimal:
        return ClinicalPalette.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _tone.withValues(alpha: 0.06),
        border: Border.all(color: _tone.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _tone == ClinicalPalette.danger
                    ? Icons.priority_high_rounded
                    : Icons.shield_outlined,
                color: _tone,
                size: 18,
              ),
              const Gap.h(ClinicalSpace.sm),
              Text(
                assessment.tierLabel.toUpperCase(),
                style: TextStyle(
                  color: _tone,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.sm),
          Text(
            assessment.headline,
            style: TextStyle(
              color: _tone,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const Gap.v(ClinicalSpace.sm + 2),
          Text(
            assessment.disposition,
            style: const TextStyle(
              color: ClinicalPalette.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (hasAny) ...<Widget>[
            const Gap.v(ClinicalSpace.sm + 2),
            Container(
              padding: const EdgeInsets.all(ClinicalSpace.sm + 2),
              decoration: BoxDecoration(
                color: ClinicalPalette.surface,
                borderRadius: BorderRadius.circular(ClinicalRadii.chip),
              ),
              child: Text(
                'Rationale: ${assessment.rationale}',
                style: ClinicalText.caption.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Note section ────────────────────────────────────────────────────

/// Paste-ready clinical note + copy action. The note is the engine's
/// formatted multi-line summary; tapping Copy fires the polished
/// toast.
class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.assessment, required this.onCopy});

  final SuicideRiskAssessment assessment;
  final VoidCallback onCopy;

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
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('CLINICAL NOTE', style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.sm + 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClinicalSpace.sm + 2),
            decoration: BoxDecoration(
              color: ClinicalPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(ClinicalRadii.chip),
            ),
            child: SelectableText(
              assessment.clinicalNote(),
              style: const TextStyle(
                color: ClinicalPalette.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.55,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const Gap.v(ClinicalSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: PillButton(
              label: 'Copy note',
              icon: Icons.copy_rounded,
              onPressed: onCopy,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disclaimer ──────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClinicalSpace.md),
      decoration: BoxDecoration(
        color: ClinicalPalette.surfaceMuted,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.6),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Text(
        'Decision support — never a substitute for a clinical interview. '
        'Acute-tier output mandates immediate ED transfer. Document your '
        "own clinical impression, the patient's words, and what you "
        'observed in the chart.',
        style: ClinicalText.caption.copyWith(height: 1.55),
      ),
    );
  }
}
