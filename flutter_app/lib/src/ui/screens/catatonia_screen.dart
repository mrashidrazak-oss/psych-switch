// Bush-Francis Catatonia Screening Instrument — tick present signs,
// 2+ → screen positive + lorazepam-challenge guidance.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/catatonia.dart';

class CatatoniaScreen extends StatefulWidget {
  const CatatoniaScreen({super.key});

  @override
  State<CatatoniaScreen> createState() => _CatatoniaScreenState();
}

class _CatatoniaScreenState extends State<CatatoniaScreen> {
  final Set<String> _present = <String>{};

  void _toggle(String id) {
    setState(() {
      if (_present.contains(id)) {
        _present.remove(id);
      } else {
        _present.add(id);
      }
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_present.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final result = evaluateCatatonia(_present);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatonia screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_present.isNotEmpty)
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
                  const Text(
                    'Tick every sign present on examination. Two or '
                    'more positive signs prompts the full rating scale '
                    'and a lorazepam challenge.',
                    style: ClinicalText.body,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  for (final s in kBfcsiSigns) ...<Widget>[
                    _SignRow(
                      sign: s,
                      present: _present.contains(s.id),
                      onTap: () => _toggle(s.id),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
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
  final CatatoniaResult result;

  @override
  Widget build(BuildContext context) {
    final pos = result.screenPositive;
    final tone =
        pos ? ClinicalPalette.toneRose : ClinicalPalette.toneMint;
    final ink = pos
        ? ClinicalPalette.toneRoseInk
        : ClinicalPalette.toneMintInk;
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
            '${result.positiveCount}',
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
              '/ 14',
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
              pos ? 'SCREEN +' : 'screen −',
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

class _SignRow extends StatelessWidget {
  const _SignRow({
    required this.sign,
    required this.present,
    required this.onTap,
  });

  final CatatoniaSign sign;
  final bool present;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: present
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
                  color: present
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: present
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 1.2,
                  ),
                ),
                child: present
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
                      sign.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: present
                            ? ClinicalPalette.ctaText
                            : ClinicalPalette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sign.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: present
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
  final CatatoniaResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Next step',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.headline,
            style: ClinicalText.subtitle.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            result.recommendation,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy summary',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.clipboardSummary()),
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
              'Bush-Francis 1996 screening instrument. Exclude NMS / '
              'a delirious or medical cause and avoid antipsychotics '
              'until malignant catatonia is excluded.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
