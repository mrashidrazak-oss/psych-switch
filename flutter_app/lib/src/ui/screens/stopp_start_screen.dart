// STOPP / START — geriatric deprescribing aid.
//
// Pick the patient's psychotropic regimen → see every STOPP rule it
// triggers (deprescribe / switch) and the START prompts (initiate
// where appropriate). Built for the moment a psychiatrist sits with
// an 80-year-old on six tablets and asks "what shouldn't be here?".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/stopp_start.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';

class StoppStartScreen extends ConsumerStatefulWidget {
  const StoppStartScreen({super.key});

  @override
  ConsumerState<StoppStartScreen> createState() => _StoppStartScreenState();
}

class _StoppStartScreenState extends ConsumerState<StoppStartScreen> {
  final Set<String> _picked = <String>{};

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
      }
    });
    unawaited(hapticsTap());
  }

  void _clear() {
    setState(_picked.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('STOPP / START'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_picked.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
            ),
        ],
      ),
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, _) => EngineErrorView(error: e),
          data: (engine) => _Body(
            engine: engine,
            picked: _picked,
            onToggle: _toggle,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.engine,
    required this.picked,
    required this.onToggle,
  });

  final SwitchingEngine engine;
  final Set<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final matches = applyStoppStart(picked.toList());
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.lg,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xxl,
      ),
      children: <Widget>[
        const _Hero(),
        const SizedBox(height: ClinicalSpace.lg),
        _RegimenPicker(
          engine: engine,
          picked: picked,
          onToggle: onToggle,
        ),
        if (picked.isNotEmpty) ...<Widget>[
          const SizedBox(height: ClinicalSpace.lg),
          _RulesSection(matches: matches),
        ],
        const SizedBox(height: ClinicalSpace.lg),
        const _Disclaimer(),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.tonePeach,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Geriatric review',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.tonePeachInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Deprescribing prompts for the over-65 regimen',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.tonePeachInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            "STOPP rules surface psychotropics that usually shouldn't "
            "be in an older patient's chart. START prompts highlight "
            'evidence-based additions worth considering. Adapted from '
            "O'Mahony 2015 (v2).",
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.tonePeachInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegimenPicker extends StatelessWidget {
  const _RegimenPicker({
    required this.engine,
    required this.picked,
    required this.onToggle,
  });

  final SwitchingEngine engine;
  final Set<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    // Build the candidate list = all STOPP-related drug ids ∪ drugs
    // in registry — restrict to those present in the engine so we
    // don't surface orphan ids.
    final candidateIds = <String>{};
    for (final r in kStoppStartRules) {
      candidateIds.addAll(r.drugIds);
    }
    final candidates = <Drug>[];
    for (final id in candidateIds) {
      final d = engine.getDrug(id);
      if (d != null) candidates.add(d);
    }
    candidates.sort((a, b) => a.genericName.compareTo(b.genericName));

    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tick what the patient is on',
            style: ClinicalText.subtitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Only drugs that participate in a STOPP/START rule are '
            'shown.',
            style: ClinicalText.caption,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final d in candidates)
                _DrugChip(
                  drug: d,
                  selected: picked.contains(d.id),
                  onTap: () => onToggle(d.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrugChip extends StatelessWidget {
  const _DrugChip({
    required this.drug,
    required this.selected,
    required this.onTap,
  });

  final Drug drug;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md + 2,
            vertical: ClinicalSpace.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: ClinicalPalette.ctaText,
                  ),
                ),
              Text(
                drug.genericName,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? ClinicalPalette.ctaText
                      : ClinicalPalette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({required this.matches});
  final List<StoppMatch> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const SquircleCard(
        tone: ClinicalPalette.toneMint,
        padding: EdgeInsets.all(ClinicalSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.check_rounded,
                color: ClinicalPalette.toneMintInk),
            SizedBox(width: ClinicalSpace.md),
            Expanded(
              child: Text(
                'No STOPP / START rules triggered for this regimen.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ClinicalPalette.toneMintInk,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final stopps = matches.where((m) => m.rule.kind == RuleKind.stopp).toList();
    final starts = matches.where((m) => m.rule.kind == RuleKind.start).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (stopps.isNotEmpty) ...<Widget>[
          const Text('STOPP — consider deprescribing',
              style: ClinicalText.subtitle),
          const SizedBox(height: ClinicalSpace.sm),
          for (var i = 0; i < stopps.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: ClinicalSpace.sm + 2),
            _RuleCard(match: stopps[i]),
          ],
        ],
        if (starts.isNotEmpty) ...<Widget>[
          const SizedBox(height: ClinicalSpace.lg),
          const Text('START — consider initiating',
              style: ClinicalText.subtitle),
          const SizedBox(height: ClinicalSpace.sm),
          for (var i = 0; i < starts.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: ClinicalSpace.sm + 2),
            _RuleCard(match: starts[i]),
          ],
        ],
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.match});
  final StoppMatch match;

  @override
  Widget build(BuildContext context) {
    final isStopp = match.rule.kind == RuleKind.stopp;
    final tone =
        isStopp ? ClinicalPalette.tonePeach : ClinicalPalette.toneMint;
    final ink = isStopp
        ? ClinicalPalette.tonePeachInk
        : ClinicalPalette.toneMintInk;
    return SquircleCard(
      tone: tone,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TonePill(
                label: isStopp ? 'STOPP' : 'START',
                tone: const Color(0xFFFFFFFF),
                ink: ink,
              ),
              const Spacer(),
              if (match.matchedDrugIds.isNotEmpty)
                Text(
                  match.matchedDrugIds.join(', '),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ink.withValues(alpha: 0.8),
                    letterSpacing: 0.4,
                  ),
                ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            match.rule.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ink,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            match.rule.rationale,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ink,
              height: 1.5,
            ),
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
              'STOPP / START prompts are not blanket bans — they are '
              'discussion starters. Confirm patient-specific '
              'indications, weigh risk-benefit, and document the '
              'reasoning.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
