// About screen.
//
// Renders live build info pulled from package_info_plus + the loaded
// engine, plus a static block for license + contact + project links.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/errata.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    final asyncPkg = ref.watch(_packageInfoProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
            final version = asyncPkg.value?.version ?? '—';
            final build = asyncPkg.value?.buildNumber ?? '—';
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg + 4,
                AppSpace.xl,
                AppSpace.lg + 4,
                AppSpace.xl,
              ),
              children: <Widget>[
                // Hero — wordmark + tagline + monogram.
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[AppColors.from, AppColors.to],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            blurRadius: 14,
                            spreadRadius: -3,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const Gap.h(AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'PsychSwitch',
                            style: AppTextSizes.heading,
                          ),
                          const Gap.v(2),
                          Text(
                            'Reviewed cross-titration · cited at every step',
                            style: AppTextSizes.caption.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap.v(AppSpace.xl),

                _StatGrid(
                  stats: <_Stat>[
                    _Stat(label: 'Version', value: '$version+$build'),
                    _Stat(
                      label: 'Drugs',
                      value:
                          '${engine.listAllDrugs().length} (${engine.listDrugs().length} visible)',
                    ),
                    _Stat(
                      label: 'Reviewed rules',
                      value: '${engine.listRules().length}',
                    ),
                    _Stat(label: 'Errata logged', value: '${errataCount()}'),
                  ],
                ),
                const Gap.v(AppSpace.xl),

                const _Section(
                  title: 'CLINICAL SCOPE',
                  body:
                      'Antidepressants and oral antipsychotics. Mood stabilisers '
                      'and LAI depot protocols are also in the registry but the '
                      'switch picker keeps them gated — both classes need more '
                      'clinical research before generic templating is safe.',
                ),
                const Gap.v(AppSpace.lg),

                const _Section(
                  title: 'INTENDED USE',
                  body:
                      'Decision support for psychiatrists, not a substitute for '
                      'clinical judgement. Every switch should still be reviewed '
                      'against the patient in front of you and the primary '
                      'references the rule cites.',
                ),
                const Gap.v(AppSpace.lg),

                const _Section(
                  title: 'PRIVACY',
                  body:
                      'On-device only. Saved cases live in a local SQLite '
                      'database. The optional crash-reporting toggle (Sentry) '
                      'never transmits clinical inputs. No network calls are '
                      'made by the engine itself.',
                ),
                const Gap.v(AppSpace.lg),

                const _Section(
                  title: 'LICENSING',
                  body:
                      'App source: MIT. Clinical content '
                      '(drug profiles, switching rules, citations, errata): '
                      'CC BY-NC-SA 4.0.',
                ),
                const Gap.v(AppSpace.lg),

                const _Section(
                  title: 'CONTACT',
                  body: 'errata@psychswitch.health · privacy@psychswitch.health',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2-up grid; on tight widths fall back to 1 column.
        final twoUp = constraints.maxWidth >= 320;
        final itemWidth = twoUp
            ? (constraints.maxWidth - AppSpace.sm) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: stats
              .map(
                (s) => SizedBox(
                  width: itemWidth,
                  child: _StatChip(stat: s),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat});

  final _Stat stat;

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
        AppSpace.sm + 2,
        AppSpace.md + 2,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(stat.label.toUpperCase(), style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs),
          Text(
            stat.value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextSizes.eyebrow),
        const Gap.v(AppSpace.xs + 2),
        Text(
          body,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
