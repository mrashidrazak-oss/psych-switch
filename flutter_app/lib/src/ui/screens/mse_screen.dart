// MSE narrative generator — tap an anchor per domain, the app emits a
// paste-ready paragraph for the clinical note.
//
// Each domain renders as a card with horizontally-wrapped anchor pills.
// Tapping a pill selects it (radio behaviour per domain). Above the
// domains lives the live narrative card which updates as picks change
// and exposes a "Copy" pill.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/mse.dart';

class MseScreen extends StatefulWidget {
  const MseScreen({super.key});

  @override
  State<MseScreen> createState() => _MseScreenState();
}

class _MseScreenState extends State<MseScreen> {
  final Map<String, String> _picks = <String, String>{};

  void _pick(String domain, String anchor) {
    setState(() {
      if (_picks[domain] == anchor) {
        _picks.remove(domain);
      } else {
        _picks[domain] = anchor;
      }
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_picks.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final narrative = generateMseNarrative(picks: _picks);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MSE generator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_picks.isNotEmpty)
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
        ],
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
            _NarrativeCard(
              narrative: narrative,
              filled: _picks.isNotEmpty,
            ),
            const SizedBox(height: ClinicalSpace.lg),
            for (var i = 0; i < kMseDomains.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: ClinicalSpace.md),
              _DomainCard(
                domain: kMseDomains[i],
                pickedId: _picks[kMseDomains[i].id],
                onPick: (id) => _pick(kMseDomains[i].id, id),
              ),
            ],
            const SizedBox(height: ClinicalSpace.md),
            const _FooterDisclaimer(),
          ],
        ),
      ),
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({required this.narrative, required this.filled});
  final String narrative;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneLavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              TonePill(
                label: 'Live narrative',
                tone: Color(0xFFFFFFFF),
                ink: ClinicalPalette.toneLavenderInk,
              ),
              Spacer(),
              Icon(Icons.edit_note_rounded,
                  size: 18, color: ClinicalPalette.toneLavenderInk),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            narrative,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
              color: ClinicalPalette.toneLavenderInk,
              height: 1.6,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy narrative',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: filled
                ? () async {
                    await Clipboard.setData(
                      ClipboardData(text: narrative),
                    );
                    unawaited(hapticsConfirm());
                    if (!context.mounted) return;
                    showCopiedToast(context, label: 'Narrative');
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.domain,
    required this.pickedId,
    required this.onPick,
  });

  final MseDomain domain;
  final String? pickedId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(domain.eyebrow, style: ClinicalText.eyebrow),
              const Spacer(),
              if (pickedId != null)
                const Icon(Icons.check_circle,
                    size: 14, color: ClinicalPalette.success),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            domain.label,
            style: ClinicalText.subtitle
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final a in domain.anchors)
                _AnchorChip(
                  anchor: a,
                  selected: pickedId == a.id,
                  onTap: () => onPick(a.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorChip extends StatelessWidget {
  const _AnchorChip({
    required this.anchor,
    required this.selected,
    required this.onTap,
  });

  final MseAnchor anchor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md,
            vertical: ClinicalSpace.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_rounded,
                      size: 13, color: ClinicalPalette.ctaText),
                ),
              Text(
                anchor.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? ClinicalPalette.ctaText
                      : ClinicalPalette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterDisclaimer extends StatelessWidget {
  const _FooterDisclaimer();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.edit_outlined,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Use the generated paragraph as the skeleton. Edit '
              'inline before pasting into the chart — patient-specific '
              'detail always trumps a templated phrase.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
