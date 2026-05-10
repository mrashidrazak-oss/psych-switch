// Mood-stabilizer detail — single drug profile (dosing, PK, CYP
// interactions, citations). RN parity:
// `screens/MoodStabilizerDetailScreen.tsx`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

class MoodStabilizerDetailScreen extends ConsumerWidget {
  const MoodStabilizerDetailScreen({required this.drugId, super.key});

  final String drugId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood stabilizer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (engine) {
            final drug = engine.getDrug(drugId);
            if (drug == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpace.xl),
                child: Center(
                  child: Text(
                    'Drug not found.',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg + 4,
                AppSpace.lg,
                AppSpace.lg + 4,
                AppSpace.xl,
              ),
              children: <Widget>[
                EntranceFade(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        drug.genericName,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Gap.v(AppSpace.xs),
                      Text(drug.drugClass, style: AppTextSizes.caption),
                      const Gap.v(2),
                      Text(
                        drug.malaysianBrandNames.join(' · '),
                        style: AppTextSizes.micro,
                      ),
                    ],
                  ),
                ),
                const Gap.v(AppSpace.lg),

                // ── Dosing ────────────────────────────────────────
                EntranceFade(
                  index: 1,
                  child: _Section(
                    title: 'DOSING',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _InfoRow(
                          label: 'Starting dose',
                          value: '${_fmt(drug.dosing.startingDoseMg)} mg',
                        ),
                        _InfoRow(
                          label: 'Typical range',
                          value:
                              '${_fmt(drug.dosing.typicalTargetRangeMg[0])}–'
                              '${_fmt(drug.dosing.typicalTargetRangeMg[1])} mg/day',
                        ),
                        _InfoRow(
                          label: 'Maximum dose',
                          value: '${_fmt(drug.dosing.maxDoseMg)} mg/day',
                        ),
                        const Gap.v(AppSpace.sm),
                        Text(
                          'AVAILABLE IN MALAYSIA',
                          style: AppTextSizes.eyebrow.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const Gap.v(AppSpace.xs),
                        for (final f in drug.dosing.formulationsAvailableMy)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $f',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        if (drug.formulationNotes.isNotEmpty) ...<Widget>[
                          const Gap.v(AppSpace.sm),
                          Text(
                            drug.formulationNotes,
                            style: AppTextSizes.micro.copyWith(
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                // ── PK ────────────────────────────────────────────
                EntranceFade(
                  index: 2,
                  child: _Section(
                    title: 'PHARMACOKINETICS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _InfoRow(
                          label: 'Half-life',
                          value: '${_fmt(drug.halfLife.meanHours)}h mean '
                              '(${_fmt(drug.halfLife.rangeHours[0])}–'
                              '${_fmt(drug.halfLife.rangeHours[1])}h)',
                        ),
                        if (drug.halfLife.notes != null) ...<Widget>[
                          const Gap.v(AppSpace.sm),
                          Text(
                            drug.halfLife.notes!,
                            style: AppTextSizes.micro.copyWith(height: 1.5),
                          ),
                        ],
                        if (drug.activeMetabolite.clinicallySignificant) ...<Widget>[
                          const Gap.v(AppSpace.md),
                          const Divider(height: 1),
                          const Gap.v(AppSpace.md),
                          _InfoRow(
                            label: 'Active metabolite',
                            value: drug.activeMetabolite.name ?? '—',
                          ),
                          if (drug.activeMetabolite.notes != null) ...<Widget>[
                            const Gap.v(AppSpace.xs),
                            Text(
                              drug.activeMetabolite.notes!,
                              style: AppTextSizes.micro.copyWith(height: 1.5),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                // ── CYP / interactions ─────────────────────────────
                EntranceFade(
                  index: 3,
                  child: _Section(
                    title: 'DRUG INTERACTIONS (SWITCHING RELEVANCE)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (drug.cypInteractions.substrateOf.isNotEmpty)
                          _InfoRow(
                            label: 'Substrate of',
                            value: drug.cypInteractions.substrateOf.join(', '),
                          ),
                        if (drug.cypInteractions.inhibitorOf.isNotEmpty)
                          _InfoRow(
                            label: 'Inhibitor of',
                            value: drug.cypInteractions.inhibitorOf.join(', '),
                          ),
                        const Gap.v(AppSpace.sm),
                        Text(
                          drug.cypInteractions.switchingRelevance,
                          style: AppTextSizes.micro.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                // ── Citations ──────────────────────────────────────
                EntranceFade(
                  index: 4,
                  child: _Section(
                    title: 'CITATIONS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (var i = 0; i < drug.citations.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '[${i + 1}] ${drug.citations[i]}',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        const Gap.v(AppSpace.sm),
                        Text(
                          'Reviewed by: ${drug.reviewedBy} · '
                          '${drug.lastReviewedISO}',
                          style: AppTextSizes.micro,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextSizes.eyebrow),
        const Gap.v(AppSpace.sm),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md + 2,
            AppSpace.md,
            AppSpace.md + 2,
            AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(label, style: AppTextSizes.micro),
          ),
          const Gap.h(AppSpace.sm),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

String _fmt(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}
