// Pregnancy + Lactation Safety Atlas — a per-drug safety panel for the
// OB-psych question. Search by drug; each row shows two tier chips
// (pregnancy axis · lactation axis) on the same line so the answer is
// readable at a glance.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/pregnancy_lactation.dart';

class PerinatalScreen extends StatefulWidget {
  const PerinatalScreen({super.key});

  @override
  State<PerinatalScreen> createState() => _PerinatalScreenState();
}

class _PerinatalScreenState extends State<PerinatalScreen> {
  String _query = '';
  PerinatalProfile? _expanded;

  List<PerinatalProfile> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return List<PerinatalProfile>.from(kPerinatalAtlas);
    return kPerinatalAtlas
        .where((p) =>
            p.drugName.toLowerCase().contains(q) ||
            p.drugId.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy & lactation'),
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
              decoration: const InputDecoration(
                hintText: 'Filter by drug name',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: ClinicalSpace.md),
            if (rows.isEmpty)
              SquircleCard(
                child: Center(
                  child: Text(
                    'No drugs match "$_query".',
                    style: ClinicalText.caption,
                  ),
                ),
              )
            else
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: ClinicalSpace.sm + 2),
                _ProfileTile(
                  profile: rows[i],
                  expanded: _expanded?.drugId == rows[i].drugId,
                  onTap: () => setState(() {
                    _expanded =
                        _expanded?.drugId == rows[i].drugId ? null : rows[i];
                  }),
                ),
              ],
            const SizedBox(height: ClinicalSpace.lg),
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
            label: 'Perinatal atlas',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneRoseInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Pregnancy and lactation, side by side',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneRoseInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Two-axis tiers per drug (preferred · use with caution · '
            'avoid). Drawn from Maudsley 15e, LactMed, UKTIS. Tap a '
            'drug to read the per-axis rationale.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneRoseInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

({Color tone, Color ink, IconData icon}) _styleFor(PerinatalTier t) {
  switch (t) {
    case PerinatalTier.preferred:
      return (
        tone: ClinicalPalette.toneMint,
        ink: ClinicalPalette.toneMintInk,
        icon: Icons.check_rounded,
      );
    case PerinatalTier.cautious:
      return (
        tone: ClinicalPalette.toneSand,
        ink: ClinicalPalette.toneSandInk,
        icon: Icons.warning_amber_rounded,
      );
    case PerinatalTier.avoid:
      return (
        tone: ClinicalPalette.tonePeach,
        ink: ClinicalPalette.tonePeachInk,
        icon: Icons.block_rounded,
      );
    case PerinatalTier.unknown:
      return (
        tone: ClinicalPalette.surfaceMuted,
        ink: ClinicalPalette.mutedStrong,
        icon: Icons.help_outline,
      );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.expanded,
    required this.onTap,
  });

  final PerinatalProfile profile;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return SquircleCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md + 2,
              ClinicalSpace.md,
              ClinicalSpace.md + 2,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    p.drugName,
                    style: ClinicalText.subtitle
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _TierChip(
                  axis: 'Pregnancy',
                  tier: p.pregnancyTier,
                ),
                const SizedBox(width: 6),
                _TierChip(
                  axis: 'Lactation',
                  tier: p.lactationTier,
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: ClinicalPalette.mutedStrong,
                  ),
                ),
              ],
            ),
          ),
          if (expanded) ...<Widget>[
            const Divider(height: 0.5, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.all(ClinicalSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _AxisBlock(
                    axis: 'Pregnancy',
                    tier: p.pregnancyTier,
                    note: p.pregnancyNote,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _AxisBlock(
                    axis: 'Lactation',
                    tier: p.lactationTier,
                    note: p.lactationNote,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  Text(
                    p.sources,
                    style: ClinicalText.caption.copyWith(
                      color: ClinicalPalette.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  PillButton(
                    label: 'Copy summary',
                    icon: Icons.copy_rounded,
                    expanded: true,
                    onPressed: () async {
                      final text = '${p.drugName} · Pregnancy: '
                          '${tierLabel(p.pregnancyTier)}; Lactation: '
                          '${tierLabel(p.lactationTier)}. '
                          '(${p.sources})';
                      await Clipboard.setData(ClipboardData(text: text));
                      unawaited(hapticsConfirm());
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Summary copied')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.axis, required this.tier});
  final String axis;
  final PerinatalTier tier;

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: s.tone,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(s.icon, size: 11, color: s.ink),
          const SizedBox(width: 4),
          Text(
            axis.substring(0, 1).toUpperCase() + axis.substring(1, 4),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: s.ink,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisBlock extends StatelessWidget {
  const _AxisBlock({
    required this.axis,
    required this.tier,
    required this.note,
  });

  final String axis;
  final PerinatalTier tier;
  final String note;

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(tier);
    return Container(
      padding: const EdgeInsets.all(ClinicalSpace.md),
      decoration: BoxDecoration(
        color: s.tone,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(s.icon, size: 16, color: s.ink),
              const SizedBox(width: 6),
              Text(
                axis.toUpperCase(),
                style: ClinicalText.eyebrow.copyWith(
                  color: s.ink,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                tierLabel(tier),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: s.ink,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: s.ink,
              fontWeight: FontWeight.w500,
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
              'Clinical summary, not personalised advice. Specialist '
              'perinatal-psychiatry input is the standard for active '
              'decisions; this atlas is a starting point.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
