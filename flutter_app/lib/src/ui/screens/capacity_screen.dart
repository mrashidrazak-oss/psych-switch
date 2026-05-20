// Aid to Capacity Evaluation (ACE) — four-limb capacity assessment.
//
// Etchells E et al. Aid to Capacity Evaluation. Joint Centre for
// Bioethics, University of Toronto. Free clinical instrument.
//
// The clinician ticks "preserved / impaired / not assessed" for each
// of the four limbs. Capacity is preserved only when ALL four limbs
// are intact for the specific decision in question. Free-text notes
// can be added per limb to anchor the assessment to specific
// questions / patient quotes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';

enum _LimbState { unassessed, preserved, impaired }

class _Limb {
  const _Limb({
    required this.id,
    required this.title,
    required this.prompt,
    required this.example,
  });
  final String id;
  final String title;
  final String prompt;
  final String example;
}

const _limbs = <_Limb>[
  _Limb(
    id: 'understand',
    title: 'Understand',
    prompt: 'Does the patient understand the medical issue, the '
        'proposed intervention, the alternatives, and the consequences '
        'of each?',
    example: 'e.g. "Can you tell me back in your own words why we '
        'recommend this medication?"',
  ),
  _Limb(
    id: 'retain',
    title: 'Retain',
    prompt: 'Can the patient retain the information long enough to use '
        'it in the decision?',
    example: 'e.g. Ask again 10 minutes later; can they recall the '
        'main points?',
  ),
  _Limb(
    id: 'weigh',
    title: 'Weigh / use',
    prompt: 'Can the patient weigh the information against personal '
        'values + foreseeable consequences?',
    example: 'e.g. "What do you think will happen if you do / don\'t '
        'have this treatment?"',
  ),
  _Limb(
    id: 'communicate',
    title: 'Communicate',
    prompt: 'Can the patient communicate a decision (by any means)?',
    example: 'e.g. Verbal, written, signed, blinked answer — any '
        'reliable channel is sufficient.',
  ),
];

class CapacityScreen extends StatefulWidget {
  const CapacityScreen({super.key});

  @override
  State<CapacityScreen> createState() => _CapacityScreenState();
}

class _CapacityScreenState extends State<CapacityScreen> {
  final Map<String, _LimbState> _states = <String, _LimbState>{
    for (final l in _limbs) l.id: _LimbState.unassessed,
  };
  final Map<String, TextEditingController> _notes = <String,
      TextEditingController>{
    for (final l in _limbs) l.id: TextEditingController(),
  };
  final _decisionCtl = TextEditingController();

  @override
  void dispose() {
    _decisionCtl.dispose();
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setState(String id, _LimbState s) {
    setState(() => _states[id] = s);
    unawaited(hapticsTap());
  }

  bool get _allPreserved =>
      _states.values.every((s) => s == _LimbState.preserved);
  bool get _anyImpaired =>
      _states.values.any((s) => s == _LimbState.impaired);
  bool get _anyAssessed =>
      _states.values.any((s) => s != _LimbState.unassessed);

  String _summary() {
    final decision = _decisionCtl.text.trim();
    final lines = <String>[
      if (decision.isNotEmpty)
        'Decision in question: $decision'
      else
        'Decision in question: —',
      '',
      'Capacity verdict: ${_verdict()}',
      '',
      'Four-limb assessment (ACE):',
      for (final l in _limbs)
        ' · ${l.title}: ${_labelFor(_states[l.id]!)}${_notes[l.id]!.text.trim().isEmpty ? "" : " — ${_notes[l.id]!.text.trim()}"}',
    ];
    return lines.join('\n');
  }

  String _verdict() {
    if (!_anyAssessed) return 'pending';
    if (_anyImpaired) return 'IMPAIRED — capacity LACKS for this decision';
    if (_allPreserved) {
      return 'PRESERVED — capacity present for this decision';
    }
    return 'INCOMPLETE — not all four limbs assessed';
  }

  String _labelFor(_LimbState s) {
    switch (s) {
      case _LimbState.preserved:
        return 'preserved';
      case _LimbState.impaired:
        return 'impaired';
      case _LimbState.unassessed:
        return 'not assessed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capacity assessment'),
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
            ClinicalSpace.xxl,
          ),
          children: <Widget>[
            _Hero(verdict: _verdict()),
            const SizedBox(height: ClinicalSpace.lg),
            SquircleCard(
              padding: const EdgeInsets.all(ClinicalSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Decision in question',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  TextField(
                    controller: _decisionCtl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. starting lithium for bipolar I',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClinicalSpace.lg),
            for (final l in _limbs) ...<Widget>[
              _LimbCard(
                limb: l,
                state: _states[l.id]!,
                notesCtl: _notes[l.id]!,
                onSet: (s) => _setState(l.id, s),
              ),
              const SizedBox(height: ClinicalSpace.md),
            ],
            _SummaryCard(summary: _summary, verdict: _verdict),
            const SizedBox(height: ClinicalSpace.md),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.verdict});
  final String verdict;

  @override
  Widget build(BuildContext context) {
    var tone = ClinicalPalette.toneLavender;
    var ink = ClinicalPalette.toneLavenderInk;
    if (verdict.startsWith('PRESERVED')) {
      tone = ClinicalPalette.toneMint;
      ink = ClinicalPalette.toneMintInk;
    } else if (verdict.startsWith('IMPAIRED')) {
      tone = ClinicalPalette.toneRose;
      ink = ClinicalPalette.toneRoseInk;
    }
    return SquircleCard(
      tone: tone,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TonePill(
            label: 'Aid to Capacity Evaluation',
            tone: const Color(0xFFFFFFFF),
            ink: ink,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Four limbs · one decision',
            style: ClinicalText.heading.copyWith(color: ink),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Capacity is decision-specific. Mark each limb '
            'preserved / impaired against the decision in question; '
            'all four must be intact for capacity to be present.',
            style: ClinicalText.body.copyWith(
              color: ink.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimbCard extends StatelessWidget {
  const _LimbCard({
    required this.limb,
    required this.state,
    required this.notesCtl,
    required this.onSet,
  });

  final _Limb limb;
  final _LimbState state;
  final TextEditingController notesCtl;
  final ValueChanged<_LimbState> onSet;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(limb.title.toUpperCase(), style: ClinicalText.eyebrow),
              const Spacer(),
              if (state == _LimbState.preserved)
                const Icon(Icons.check_circle,
                    size: 16, color: ClinicalPalette.success)
              else if (state == _LimbState.impaired)
                const Icon(Icons.cancel,
                    size: 16, color: ClinicalPalette.danger),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            limb.prompt,
            style: ClinicalText.body.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(limb.example, style: ClinicalText.caption.copyWith(height: 1.5)),
          const SizedBox(height: ClinicalSpace.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _StateChip(
                  label: 'Preserved',
                  selected: state == _LimbState.preserved,
                  tone: ClinicalPalette.toneMint,
                  ink: ClinicalPalette.toneMintInk,
                  onTap: () => onSet(_LimbState.preserved),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StateChip(
                  label: 'Impaired',
                  selected: state == _LimbState.impaired,
                  tone: ClinicalPalette.toneRose,
                  ink: ClinicalPalette.toneRoseInk,
                  onTap: () => onSet(_LimbState.impaired),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StateChip(
                  label: 'Skip',
                  selected: state == _LimbState.unassessed,
                  tone: ClinicalPalette.surfaceMuted,
                  ink: ClinicalPalette.mutedStrong,
                  onTap: () => onSet(_LimbState.unassessed),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          TextField(
            controller: notesCtl,
            decoration: const InputDecoration(
              hintText: 'Patient quote / observation (optional)',
            ),
            maxLines: null,
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.selected,
    required this.tone,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color tone;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? tone : ClinicalPalette.surface,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : ClinicalPalette.border,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(ClinicalRadii.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? ink : ClinicalPalette.text,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.verdict});
  final String Function() summary;
  final String Function() verdict;

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
            verdict(),
            style: ClinicalText.subtitle.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Tap "Copy" to drop the full per-limb breakdown into your '
            "clipboard, ready for the patient's chart.",
            style: ClinicalText.caption.copyWith(
              color: ClinicalPalette.toneSandInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy summary',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: summary()));
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

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.gavel_outlined,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Aid to Capacity Evaluation — Etchells et al., '
              'Joint Centre for Bioethics, University of Toronto. '
              'Capacity is decision-specific and time-bound; '
              're-assess when context changes.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
