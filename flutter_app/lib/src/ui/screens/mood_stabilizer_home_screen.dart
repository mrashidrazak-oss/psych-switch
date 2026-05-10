// Mood-stabilizer module home — overview of lithium, valproate,
// lamotrigine and carbamazepine with key safety flags. RN parity:
// `screens/MoodStabilizerHomeScreen.tsx`.
//
// Each tile carries a severity-tinted left stripe + a one-line
// safety badge. Tap to open the per-drug detail screen. A dedicated
// "Stopping lithium" Banner-style tile routes to the lithium taper
// screen (Maudsley 15 Box 2.3).
//
// The bottom callout summarises the two CYP-driven LTG interactions
// (CBZ → LTG, VPA → LTG) — these are the ones clinicians most often
// miss when switching off an enzyme inducer/inhibitor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch_engine/switching_engine.dart';

const List<String> _moodStabilizerIds = <String>[
  'lithium',
  'valproate',
  'lamotrigine',
  'carbamazepine',
];

class _KeyFlag {
  const _KeyFlag(this.label, this.tone);
  final String label;
  final Color tone;
}

const Map<String, _KeyFlag> _keyFlag = <String, _KeyFlag>{
  'lithium': _KeyFlag(
    'Narrow therapeutic index — level monitoring mandatory',
    AppColors.warning,
  ),
  'valproate': _KeyFlag(
    'High teratogenicity — contraindicated in WoCBP without EURAP',
    AppColors.danger,
  ),
  'lamotrigine': _KeyFlag(
    'SJS risk — SLOW titration mandatory, stop on rash',
    AppColors.danger,
  ),
  'carbamazepine': _KeyFlag(
    'HLA-B*1502 screen MANDATORY in Asians before prescribing',
    AppColors.danger,
  ),
};

class MoodStabilizerHomeScreen extends ConsumerWidget {
  const MoodStabilizerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood stabilizers'),
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg + 4,
                AppSpace.lg,
                AppSpace.lg + 4,
                AppSpace.xl,
              ),
              children: <Widget>[
                EntranceFade(
                  child: Text(
                    'Lithium, valproate, lamotrigine, carbamazepine. '
                    'Includes switching guidance for the critical LTG '
                    'pharmacokinetic interactions.',
                    style: AppTextSizes.caption.copyWith(height: 1.55),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                for (var i = 0; i < _moodStabilizerIds.length; i++) ...<Widget>[
                  EntranceFade(
                    index: i + 1,
                    child: _DrugTile(
                      drugId: _moodStabilizerIds[i],
                      engine: engine,
                    ),
                  ),
                  const Gap.v(AppSpace.md - 2),
                ],

                EntranceFade(
                  index: 5,
                  child: _LithiumTaperTile(
                    onTap: () => context.pushNamed(Routes.lithiumTapering),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                const EntranceFade(
                  index: 6,
                  child: _SwitchingCallout(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrugTile extends StatelessWidget {
  const _DrugTile({required this.drugId, required this.engine});

  final String drugId;
  final SwitchingEngine engine;

  @override
  Widget build(BuildContext context) {
    final drug = engine.getDrug(drugId);
    if (drug == null) return const SizedBox.shrink();
    final flag = _keyFlag[drugId];
    final tone = flag?.tone ?? AppColors.border;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          Routes.moodStabilizerDetail,
          pathParameters: <String, String>{'id': drugId},
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(width: 4, color: tone),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md + 2,
                      AppSpace.md,
                      AppSpace.md + 2,
                      AppSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                drug.genericName,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Text(
                              drug.drugClass,
                              style: AppTextSizes.micro,
                            ),
                          ],
                        ),
                        const Gap.v(2),
                        Text(
                          drug.malaysianBrandNames.join(' · '),
                          style: AppTextSizes.micro,
                        ),
                        if (flag != null) ...<Widget>[
                          const Gap.v(AppSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm + 2,
                              vertical: AppSpace.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: tone.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              flag.label,
                              style: TextStyle(
                                color: tone,
                                fontSize: 11,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: AppSpace.sm),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LithiumTaperTile extends StatelessWidget {
  const _LithiumTaperTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md + 2,
            AppSpace.md,
            AppSpace.md + 2,
            AppSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.sm + 2),
                ),
                child: const Icon(
                  Icons.trending_down_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const Gap.h(AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'STOPPING LITHIUM — SLOW TAPER',
                      style: AppTextSizes.eyebrow
                          .copyWith(color: AppColors.warning),
                    ),
                    const Gap.v(AppSpace.xs),
                    const Text(
                      'Maudsley 15 Box 2.3 reduction regimen. '
                      'Manic rebound risk is 7× the untreated rate '
                      'after rapid cessation.',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.warning,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchingCallout extends StatelessWidget {
  const _SwitchingCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'SWITCHING RULES — KEY INTERACTIONS',
            style: AppTextSizes.eyebrow,
          ),
          const Gap.v(AppSpace.sm),
          const _InteractionRow(
            label: 'CBZ → LTG',
            detail:
                'As CBZ is withdrawn, LTG levels RISE (CYP induction lost). '
                'Reduce LTG dose in step.',
            tone: AppColors.danger,
          ),
          const Gap.v(AppSpace.sm),
          const _InteractionRow(
            label: 'VPA → LTG',
            detail:
                'As VPA is withdrawn, LTG levels FALL (UGT inhibition '
                'relieved). Increase LTG dose in step.',
            tone: AppColors.danger,
          ),
          const Gap.v(AppSpace.md),
          Text(
            'Use Home → Start a switch with these drug pairs to see the '
            'full step-by-step schedule.',
            style: AppTextSizes.micro.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({
    required this.label,
    required this.detail,
    required this.tone,
  });

  final String label;
  final String detail;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 3,
          height: 36,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: tone,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap.h(AppSpace.md - 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap.v(2),
              Text(
                detail,
                style: AppTextSizes.micro.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
