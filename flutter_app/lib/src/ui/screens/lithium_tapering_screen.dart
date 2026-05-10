// Lithium tapering & discontinuation guidance — Maudsley 15 Box 2.3.
// RN parity: `screens/LithiumTaperingScreen.tsx`.
//
// Stopping lithium without a slow hyperbolic taper carries a 7×
// increase in relapse risk over the untreated disorder. This screen
// surfaces:
//   • Why slow tapering matters (banner with relapse-risk numbers)
//   • The Maudsley 15 reduction regimen (step ladder)
//   • Hyperbolic principle + final-pre-stop dose guidance
//   • Withdrawal effects (physical / psychological)
//   • When to consider stopping
//   • Monitoring during the taper
//   • If symptoms emerge / Never do this (warning + danger banners)
//   • Other mood stabilisers note + citations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

class LithiumTaperingScreen extends ConsumerWidget {
  const LithiumTaperingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTaper = ref.watch(lithiumTaperingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lithium tapering'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: asyncTaper.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (data) {
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
                        data.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Gap.v(AppSpace.xs),
                      Text(
                        'Slow hyperbolic taper. Maudsley 15 — Box 2.3.',
                        style: AppTextSizes.caption.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 1,
                  child: _ToneBanner(
                    tone: AppColors.warning,
                    eyebrow: 'WHY SLOW TAPERING MATTERS',
                    body: data.rationale,
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 2,
                  child: _Section(
                    title: 'MAUDSLEY 15 REDUCTION REGIMEN (BOX 2.3)',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          for (var i = 0;
                              i < data.tapering.maudsleyRegimen.steps.length;
                              i++)
                            Container(
                              decoration: BoxDecoration(
                                border: i ==
                                        data.tapering.maudsleyRegimen.steps
                                                .length -
                                            1
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                            color: AppColors.border),
                                      ),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpace.md + 2,
                                AppSpace.sm + 2,
                                AppSpace.md + 2,
                                AppSpace.sm + 2,
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          data.tapering.maudsleyRegimen
                                              .steps[i].phase,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Gap.v(2),
                                        Text(
                                          data.tapering.maudsleyRegimen
                                              .steps[i].notes,
                                          style: AppTextSizes.micro
                                              .copyWith(height: 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap.h(AppSpace.md),
                                  Text(
                                    '−${_fmt(data.tapering.maudsleyRegimen.steps[i].stepDoseMg)} mg',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const Gap.h(AppSpace.xs),
                                  Text(
                                    data.tapering.maudsleyRegimen.steps[i]
                                        .interval,
                                    style: AppTextSizes.micro,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap.v(AppSpace.md),
                EntranceFade(
                  index: 2,
                  child: _SimpleCard(
                    title: 'TOTAL DURATION',
                    body: data.tapering.maudsleyRegimen.totalDurationNote,
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 3,
                  child: _Section(
                    title: 'HYPERBOLIC TAPERING PRINCIPLE',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md + 2,
                        AppSpace.md,
                        AppSpace.md + 2,
                        AppSpace.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            data.tapering.principle,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                          const Gap.v(AppSpace.md),
                          _Tile(
                              eyebrow: 'INITIAL REDUCTION',
                              body: data.tapering.initialReduction),
                          const Gap.v(AppSpace.sm),
                          _Tile(
                              eyebrow: 'RAPID VS GRADUAL',
                              body: data.tapering.rapidVsGradual),
                          const Gap.v(AppSpace.sm),
                          _Tile(
                              eyebrow: 'FINAL PRE-STOP DOSE',
                              body: data.tapering.minimumDoseBeforeStop),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 4,
                  child: _Section(
                    title: 'WITHDRAWAL EFFECTS',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md + 2,
                        AppSpace.md,
                        AppSpace.md + 2,
                        AppSpace.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            data.withdrawalEffects.rationale,
                            style: AppTextSizes.micro.copyWith(height: 1.5),
                          ),
                          const Gap.v(AppSpace.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _BulletColumn(
                                  eyebrow: 'PHYSICAL',
                                  bullets: data.withdrawalEffects.physical,
                                ),
                              ),
                              const Gap.h(AppSpace.md),
                              Expanded(
                                child: _BulletColumn(
                                  eyebrow: 'PSYCHOLOGICAL',
                                  bullets:
                                      data.withdrawalEffects.psychological,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 5,
                  child: _Section(
                    title: 'WHEN TO CONSIDER STOPPING',
                    child: _BulletList(items: data.whenToConsiderStopping),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 6,
                  child: _Section(
                    title: 'MONITORING DURING THE TAPER',
                    child: _BulletList(items: data.monitoringDuringTaper),
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 6,
                  child: _ToneBanner(
                    tone: AppColors.warning,
                    eyebrow: 'IF SYMPTOMS EMERGE',
                    bodyList: data.ifSymptomsEmerge,
                  ),
                ),
                const Gap.v(AppSpace.md),

                EntranceFade(
                  index: 6,
                  child: _ToneBanner(
                    tone: AppColors.danger,
                    eyebrow: 'NEVER DO THIS',
                    bodyList: data.neverDoThis,
                    bulletGlyph: '✕',
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 6,
                  child: _SimpleCard(
                    title: 'VALPROATE · LAMOTRIGINE · CARBAMAZEPINE',
                    body: data.otherMoodStabilizers,
                  ),
                ),
                const Gap.v(AppSpace.lg),

                EntranceFade(
                  index: 6,
                  child: _Section(
                    title: 'CITATIONS',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md + 2,
                        AppSpace.md,
                        AppSpace.md + 2,
                        AppSpace.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (var i = 0; i < data.citations.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '[${i + 1}] ${data.citations[i]}',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          const Gap.v(AppSpace.sm),
                          Text(
                            'Reviewed by: ${data.reviewedBy} · '
                            '${data.lastReviewedISO}',
                            style: AppTextSizes.micro,
                          ),
                        ],
                      ),
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
        child,
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.eyebrow, required this.body});
  final String eyebrow;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md - 2,
        AppSpace.sm,
        AppSpace.md - 2,
        AppSpace.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow, style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletColumn extends StatelessWidget {
  const _BulletColumn({required this.eyebrow, required this.bullets});
  final String eyebrow;
  final List<String> bullets;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md - 2,
        AppSpace.sm,
        AppSpace.md - 2,
        AppSpace.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow, style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs),
          for (final s in bullets)
            Text(
              '• $s',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: i == items.length - 1 ? 0 : AppSpace.sm),
              child: Text(
                '• ${items[i]}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToneBanner extends StatelessWidget {
  const _ToneBanner({
    required this.tone,
    required this.eyebrow,
    this.body,
    this.bodyList,
    this.bulletGlyph = '•',
  });

  final Color tone;
  final String eyebrow;
  final String? body;
  final List<String>? bodyList;
  final String bulletGlyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: AppTextSizes.eyebrow.copyWith(color: tone),
          ),
          const Gap.v(AppSpace.xs + 2),
          if (body != null)
            Text(
              body!,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          if (bodyList != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var i = 0; i < bodyList!.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == bodyList!.length - 1 ? 0 : AppSpace.sm,
                    ),
                    child: Text(
                      '$bulletGlyph ${bodyList![i]}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
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
