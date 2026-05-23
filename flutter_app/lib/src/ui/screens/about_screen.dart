// About screen — migrated to the Clinical Light language 2026-05-15.
//
// Renders live build info (package_info_plus + the loaded engine) on
// pastel squircle stat tiles, then a stack of section cards with the
// clinical scope / intended use / privacy / licensing / contact copy.
//
// Visual continuity with the redesigned Home: same palette, same
// squircle radii, same TonePill chrome. Wrapped in a local
// `Theme(data: buildClinicalTheme(), …)` so it adopts the light
// language without leaking into the rest of the (still-dark) app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
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
    return Theme(
      data: buildClinicalTheme(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: ClinicalPalette.bg,
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
              error: (e, _) => EngineErrorView(error: e),
              data: (engine) {
                final version = asyncPkg.value?.version ?? '—';
                final build = asyncPkg.value?.buildNumber ?? '—';
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
                    _StatGrid(
                      stats: <_Stat>[
                        _Stat(
                          label: 'Drugs',
                          value:
                              '${engine.listAllDrugs().length} (${engine.listDrugs().length} visible)',
                          tone: ClinicalPalette.toneSky,
                          ink: ClinicalPalette.toneSkyInk,
                        ),
                        _Stat(
                          label: 'Reviewed rules',
                          value: '${engine.listRules().length}',
                          tone: ClinicalPalette.toneMint,
                          ink: ClinicalPalette.toneMintInk,
                        ),
                        _Stat(
                          label: 'Errata logged',
                          value: '${errataCount()}',
                          tone: ClinicalPalette.tonePeach,
                          ink: ClinicalPalette.tonePeachInk,
                        ),
                        _Stat(
                          label: 'Build',
                          value: 'v$version+$build',
                          tone: ClinicalPalette.toneRose,
                          ink: ClinicalPalette.toneRoseInk,
                        ),
                      ],
                    ),
                    const SizedBox(height: ClinicalSpace.lg),
                    const _SectionCard(
                      eyebrow: 'Clinical scope',
                      body:
                          'Antidepressants and oral antipsychotics. Mood '
                          'stabilisers and LAI depot protocols are also in '
                          'the registry but the switch picker keeps them '
                          'gated — both classes need more clinical research '
                          'before generic templating is safe.',
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                    const _SectionCard(
                      eyebrow: 'Intended use',
                      body:
                          'Decision support for healthcare professionals, '
                          'not a substitute for clinical judgement. Every '
                          'switch should still be reviewed against the '
                          'patient in front of you and the primary '
                          'references the rule cites.',
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                    const _SectionCard(
                      eyebrow: 'Privacy',
                      body:
                          'On-device only. Saved cases live in a local '
                          'SQLite database. The optional crash-reporting '
                          'toggle (Sentry) never transmits clinical inputs. '
                          'No network calls are made by the engine itself.',
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                    const _SectionCard(
                      eyebrow: 'Licensing',
                      body:
                          'App source: MIT. Clinical content (drug '
                          'profiles, switching rules, citations, errata): '
                          'CC BY-NC-SA 4.0.',
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                    const _SectionCard(
                      eyebrow: 'Contact',
                      body: 'Errata  ·  errata@psychswitch.health\n'
                          'Privacy  ·  privacy@psychswitch.health',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneLavender,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
              color: Colors.white.withValues(alpha: 0.7),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: ClinicalSpace.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PsychSwitch',
                  style: ClinicalText.heading.copyWith(
                    color: ClinicalPalette.toneLavenderInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reviewed cross-titration',
                  style: ClinicalText.caption.copyWith(
                    color: ClinicalPalette.toneLavenderInk
                        .withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: ClinicalSpace.md),
                const TonePill(
                  label: 'Maudsley 15th ed.',
                  tone: Color(0xFFFFFFFF),
                  ink: ClinicalPalette.toneLavenderInk,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat grid ────────────────────────────────────────────────────────

class _Stat {
  const _Stat({
    required this.label,
    required this.value,
    required this.tone,
    required this.ink,
  });
  final String label;
  final String value;
  final Color tone;
  final Color ink;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _StatTile(stat: stats[0])),
            const SizedBox(width: ClinicalSpace.sm + 2),
            Expanded(child: _StatTile(stat: stats[1])),
          ],
        ),
        const SizedBox(height: ClinicalSpace.sm + 2),
        Row(
          children: <Widget>[
            Expanded(child: _StatTile(stat: stats[2])),
            const SizedBox(width: ClinicalSpace.sm + 2),
            Expanded(child: _StatTile(stat: stats[3])),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: stat.tone,
      radius: ClinicalRadii.tile,
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            stat.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: stat.ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: stat.ink,
              height: 1.2,
              letterSpacing: -0.2,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.eyebrow, required this.body});
  final String eyebrow;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TonePill(
            label: eyebrow,
            tone: ClinicalPalette.surfaceMuted,
            ink: ClinicalPalette.mutedStrong,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            body,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.text,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
