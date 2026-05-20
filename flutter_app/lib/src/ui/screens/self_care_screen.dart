// Clinician self-care brief — a quick weekly check on the doctor,
// not the patient. Adapted from Maslach Burnout Inventory short-form
// patterns; six 0-3 items across emotional exhaustion, '
// depersonalisation, and personal accomplishment.
//
// Score interpretation:
//   • 0–4  — sustainable: ride the week as-is
//   • 5–9  — warning: pick one recovery action this week
//   • 10–14 — concern: speak to a trusted colleague or supervisor
//   • 15–18 — burnout-zone: take time off, formal supervision /
//             occupational health referral

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';

const _items = <_SelfCareItem>[
  _SelfCareItem(
    id: 'emotionally_drained',
    prompt: 'I feel emotionally drained from work',
  ),
  _SelfCareItem(
    id: 'dread_morning',
    prompt: 'I feel a sense of dread when I think about the next workday',
  ),
  _SelfCareItem(
    id: 'depersonalised',
    prompt: 'I find myself more detached from my patients than I used to be',
  ),
  _SelfCareItem(
    id: 'accomplishment',
    prompt: 'I feel that what I am doing is making a difference (reversed)',
  ),
  _SelfCareItem(
    id: 'sleep',
    prompt: 'My sleep has been disturbed by work-related thoughts',
  ),
  _SelfCareItem(
    id: 'recovery',
    prompt: 'I find it hard to recover during evenings or days off',
  ),
];

const _anchors = <String>[
  'Not at all',
  'A little',
  'Often',
  'Nearly always',
];

class _SelfCareItem {
  const _SelfCareItem({required this.id, required this.prompt});
  final String id;
  final String prompt;
}

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  final Map<String, int> _answers = <String, int>{};

  void _set(String id, int value) {
    setState(() => _answers[id] = value);
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_answers.clear);
    unawaited(hapticsTap());
  }

  int get _total {
    var sum = 0;
    for (final i in _items) {
      sum += _answers[i.id] ?? 0;
    }
    return sum;
  }

  String _bandLabel() {
    if (_answers.isEmpty) return 'Tap to begin';
    if (_total <= 4) return 'Sustainable';
    if (_total <= 9) return 'Watchful';
    if (_total <= 14) return 'Concern';
    return 'Burnout zone';
  }

  String _bandAction() {
    if (_answers.isEmpty) {
      return 'Pick a frequency anchor on each row.';
    }
    if (_total <= 4) {
      return 'Sustainable this week. Hold onto one anchor habit '
          '(sleep, exercise, supervision) you do well.';
    }
    if (_total <= 9) {
      return 'Watchful. Pick ONE recovery action this week — '
          'protected lunch, supervision date, leave one hour earlier '
          'on the calmest day.';
    }
    if (_total <= 14) {
      return 'Concern. Speak to a trusted colleague or supervisor. '
          'Schedule explicit recovery time + reduce avoidable '
          'commitments this week.';
    }
    return 'Burnout zone. Take time off. Formal supervision or '
        'occupational-health referral. Talking to a peer-support '
        'service today is reasonable.';
  }

  ({Color tone, Color ink}) _palette() {
    if (_answers.isEmpty) {
      return (
        tone: ClinicalPalette.surfaceMuted,
        ink: ClinicalPalette.mutedStrong
      );
    }
    if (_total <= 4) {
      return (
        tone: ClinicalPalette.toneMint,
        ink: ClinicalPalette.toneMintInk
      );
    }
    if (_total <= 9) {
      return (
        tone: ClinicalPalette.toneSky,
        ink: ClinicalPalette.toneSkyInk
      );
    }
    if (_total <= 14) {
      return (
        tone: ClinicalPalette.toneSand,
        ink: ClinicalPalette.toneSandInk
      );
    }
    return (
      tone: ClinicalPalette.toneRose,
      ink: ClinicalPalette.toneRoseInk
    );
  }

  String _summary() {
    return 'Self-care brief: $_total / 18 — ${_bandLabel()}. '
        '${_bandAction()}';
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-care'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_answers.isNotEmpty)
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
            Container(
              width: double.infinity,
              color: p.tone,
              padding: const EdgeInsets.fromLTRB(
                ClinicalSpace.lg + 4,
                ClinicalSpace.md,
                ClinicalSpace.lg + 4,
                ClinicalSpace.md + 2,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '$_total',
                    style: TextStyle(
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
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
                      ' / 18',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.ink.withValues(alpha: 0.7),
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
                      _bandLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  SquircleCard(
                    padding: const EdgeInsets.all(ClinicalSpace.md + 2),
                    child: Text(
                      'Six anchored questions about the last 7 days. '
                      'No data leaves the phone. Tap to rate; the '
                      'banner updates as you go.',
                      style: ClinicalText.body
                          .copyWith(height: 1.55),
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  for (var i = 0; i < _items.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: ClinicalSpace.sm),
                    _ItemCard(
                      item: _items[i],
                      index: i + 1,
                      current: _answers[_items[i].id],
                      onPick: (v) => _set(_items[i].id, v),
                    ),
                  ],
                  const SizedBox(height: ClinicalSpace.lg),
                  _ActionCard(
                    action: _bandAction(),
                    summary: _summary,
                  ),
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.index,
    required this.current,
    required this.onPick,
  });

  final _SelfCareItem item;
  final int index;
  final int? current;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current != null
                      ? ClinicalPalette.cta
                      : ClinicalPalette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: current != null
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.mutedStrong,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Text(
                  item.prompt,
                  style: ClinicalText.subtitle
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Row(
            children: <Widget>[
              for (var i = 0; i < _anchors.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _AnchorChip(
                    score: i,
                    label: _anchors[i],
                    selected: current == i,
                    onTap: () => onPick(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorChip extends StatelessWidget {
  const _AnchorChip({
    required this.score,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int score;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: <Widget>[
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? ClinicalPalette.ctaText
                      : ClinicalPalette.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? ClinicalPalette.ctaText.withValues(alpha: 0.85)
                      : ClinicalPalette.muted,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.summary});
  final String action;
  final String Function() summary;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'For you',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            action,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy for journal',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: summary()));
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Brief copied')),
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
          const Icon(Icons.favorite_border,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'A quick check on you — not a diagnostic instrument. If '
              'you would tell a colleague to take time off, do the '
              'same for yourself.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
