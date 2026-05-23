// Shared loading + error views for the async engine provider.
//
// Every screen that watches `engineProvider` (or `loadedContentProvider`)
// uses these for the loading and error branches. Centralising them
// keeps the look consistent and prevents per-screen boilerplate.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

/// Splash shown while `assets/content_bundle.json` is decoding into a
/// `SwitchingEngine`. Cold-start typically resolves in <100 ms, but
/// when it does flash we want users to see a deliberate brand surface
/// rather than a bare spinner.
class EngineLoadingView extends StatelessWidget {
  const EngineLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Brand mark — faint, monogram-style. Animated entrance so it
          // never appears jarring on quick loads.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 8),
                child: const _BrandMark(),
              ),
            ),
          ),
          const Gap.v(ClinicalSpace.lg),
          const Text('PsychSwitch', style: ClinicalText.subtitle),
          const Gap.v(ClinicalSpace.xs),
          const Text(
            'Loading clinical registry…',
            style: ClinicalText.caption,
          ),
          const Gap.v(ClinicalSpace.xl),
          const RepaintBoundary(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real brand mark — matches the dual-tone glow treatment used by the
/// Disclaimer's `_BrandHero`. Three cold-start surfaces (loading,
/// disclaimer, about) now share one mark instead of three.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ClinicalPalette.toneLavenderInk.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(-5, 6),
          ),
          BoxShadow(
            color: ClinicalPalette.toneMintInk.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(5, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Image.asset(
          'assets/icon.png',
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// Displayed when the bundle fails to decode. This is a hard failure
/// — the app cannot function clinically without the registry. The
/// surface stays calm and actionable for the clinician (reinstall +
/// support email), while the raw error stays available behind a
/// disclosure for whoever debugs it.
class EngineErrorView extends StatefulWidget {
  const EngineErrorView({required this.error, super.key});

  final Object error;

  @override
  State<EngineErrorView> createState() => _EngineErrorViewState();
}

class _EngineErrorViewState extends State<EngineErrorView> {
  bool _detailsOpen = false;

  Future<void> _copyDetails() async {
    await Clipboard.setData(
      ClipboardData(text: widget.error.toString()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Tinted-danger glyph ─────────────────────────────────
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ClinicalPalette.danger.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: ClinicalPalette.danger,
                    size: 24,
                  ),
                ),
              ),
              const Gap.v(ClinicalSpace.lg),
              const Text(
                "Clinical content didn't load.",
                style: TextStyle(
                  color: ClinicalPalette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap.v(ClinicalSpace.sm + 2),
              Text(
                'This usually means the install was interrupted. '
                'Reinstall PsychSwitch and try again.',
                style: ClinicalText.body.copyWith(
                  color: ClinicalPalette.muted,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap.v(ClinicalSpace.md),
              Text.rich(
                TextSpan(
                  style: ClinicalText.caption.copyWith(height: 1.5),
                  children: const <InlineSpan>[
                    TextSpan(text: 'If it keeps happening, email  '),
                    TextSpan(
                      text: 'errata@psychswitch.health',
                      style: TextStyle(
                        color: ClinicalPalette.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const Gap.v(ClinicalSpace.xl),
              // ── Details disclosure ──────────────────────────────────
              _DetailsDisclosure(
                open: _detailsOpen,
                onToggle: () =>
                    setState(() => _detailsOpen = !_detailsOpen),
                error: widget.error,
                onCopy: _copyDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible technical-details card for [EngineErrorView]. Closed:
/// a single muted "Show details" row. Open: monospace error text
/// followed by a "Copy details" affordance for support emails.
class _DetailsDisclosure extends StatelessWidget {
  const _DetailsDisclosure({
    required this.open,
    required this.onToggle,
    required this.error,
    required this.onCopy,
  });

  final bool open;
  final VoidCallback onToggle;
  final Object error;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(ClinicalRadii.tile),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.lg - 2,
                vertical: ClinicalSpace.md,
              ),
              child: Row(
                children: <Widget>[
                  const Text(
                    'Show details',
                    style: TextStyle(
                      color: ClinicalPalette.mutedStrong,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: open ? 0.5 : 0,
                    child: const Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: ClinicalPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ClinicalSpace.lg - 2,
                      0,
                      ClinicalSpace.lg - 2,
                      ClinicalSpace.md + 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: ClinicalPalette.border,
                        ),
                        const Gap.v(ClinicalSpace.sm + 2),
                        SelectableText(
                          '$error',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            height: 1.5,
                            color: ClinicalPalette.mutedStrong,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const Gap.v(ClinicalSpace.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: onCopy,
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 14,
                            ),
                            label: const Text('Copy details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ClinicalPalette.accent,
                              side: BorderSide(
                                color: ClinicalPalette.accent
                                    .withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: ClinicalSpace.md + 2,
                                vertical: ClinicalSpace.xs + 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ClinicalRadii.chip,
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
