// MAOI tyramine-diet reference — searchable food list with risk
// tiers, plus the drug cautions and hypertensive-crisis script.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/maoi_diet.dart';

class MaoiDietScreen extends StatefulWidget {
  const MaoiDietScreen({super.key});

  @override
  State<MaoiDietScreen> createState() => _MaoiDietScreenState();
}

class _MaoiDietScreenState extends State<MaoiDietScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color tone, Color ink, IconData icon}) _style(TyramineRisk r) {
    switch (r) {
      case TyramineRisk.avoid:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk,
          icon: Icons.block,
        );
      case TyramineRisk.caution:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk,
          icon: Icons.warning_amber_rounded,
        );
      case TyramineRisk.safe:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk,
          icon: Icons.check_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = searchFoods(_query);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAOI diet'),
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
            const _Hero(),
            const SizedBox(height: ClinicalSpace.lg),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Search a food (e.g. cheese, beer)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: ClinicalSpace.md),
            for (final f in result.matches) ...<Widget>[
              _FoodRow(food: f, style: _style(f.risk)),
              const SizedBox(height: 6),
            ],
            if (result.matches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(ClinicalSpace.lg),
                child: Text('No matching foods.',
                    style: ClinicalText.body),
              ),
            const SizedBox(height: ClinicalSpace.md),
            _DrugCautionCard(),
            const SizedBox(height: ClinicalSpace.md),
            const _CrisisCard(),
            const SizedBox(height: ClinicalSpace.md),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneRose,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Irreversible MAOI',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneRoseInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Tyramine + drug interactions',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneRoseInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'For phenelzine / tranylcypromine / isocarboxazid (and '
            'high-dose / oral selegiline). Moclobemide carries far '
            'less dietary risk but the SAME drug-interaction risk.',
            style: ClinicalText.body.copyWith(
              color:
                  ClinicalPalette.toneRoseInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.style});
  final FoodItem food;
  final ({Color tone, Color ink, IconData icon}) style;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: style.tone,
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(style.icon, size: 18, color: style.ink),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        food.name,
                        style: ClinicalText.subtitle.copyWith(
                          color: style.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ClinicalSpace.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius:
                            BorderRadius.circular(ClinicalRadii.pill),
                      ),
                      child: Text(
                        food.risk.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: style.ink,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  food.note,
                  style: ClinicalText.caption.copyWith(
                    color: style.ink.withValues(alpha: 0.85),
                    height: 1.45,
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

class _DrugCautionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Drug cautions (the bigger killer)',
            tone: ClinicalPalette.surfaceMuted,
            ink: ClinicalPalette.mutedStrong,
          ),
          const SizedBox(height: ClinicalSpace.md),
          for (final c in kMaoiDrugCautions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.error_outline,
                        size: 14, color: ClinicalPalette.danger),
                  ),
                  const SizedBox(width: ClinicalSpace.sm + 2),
                  Expanded(
                    child: Text(c,
                        style:
                            ClinicalText.body.copyWith(height: 1.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  const _CrisisCard();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneRose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Hypertensive crisis',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneRoseInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            kHypertensiveCrisisManagement,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneRoseInk,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy crisis script',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(
                  text: kHypertensiveCrisisManagement));
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              showCopiedToast(context, label: 'Crisis script');
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
              'Tyramine content varies with storage / preparation. '
              'When unsure: fresh, in-date, properly stored food is '
              'the safest rule. Maudsley 15e / Gardner 1996.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
