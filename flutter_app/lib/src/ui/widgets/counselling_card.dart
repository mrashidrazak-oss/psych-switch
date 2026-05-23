// Counselling card — patient-facing version of the schedule, written
// in plain language. Collapsible so it doesn't dominate the screen
// when the clinician only needs the technical view.
//
// RN parity: `components/CounsellingCard.tsx`. Generates the text
// from `format_counselling.dart::formatCounsellingCard` — no LLM,
// no async.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:share_plus/share_plus.dart';

class CounsellingCard extends StatefulWidget {
  const CounsellingCard({required this.text, super.key});

  final String text;

  @override
  State<CounsellingCard> createState() => _CounsellingCardState();
}

class _CounsellingCardState extends State<CounsellingCard> {
  bool _expanded = false;

  Future<void> _onShare() async {
    unawaited(hapticsTap());
    await Share.share(
      widget.text,
      subject: 'PsychSwitch — patient counselling card',
    );
  }

  Future<void> _onCopy(BuildContext context) async {
    unawaited(hapticsTap());
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!context.mounted) return;
    showCopiedToast(context, label: 'Counselling card');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: ClinicalPalette.border),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.md + 2,
                  ClinicalSpace.md - 2,
                  ClinicalSpace.md + 2,
                  ClinicalSpace.md - 2,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ClinicalPalette.toneMintInk.withValues(alpha: 0.15),
                        border: Border.all(
                          color: ClinicalPalette.toneMintInk.withValues(alpha: 0.3),
                        ),
                        borderRadius:
                            BorderRadius.circular(ClinicalRadii.chip + 2),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: ClinicalPalette.toneMintInk,
                      ),
                    ),
                    const Gap.h(ClinicalSpace.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Patient counselling card',
                            style: TextStyle(
                              color: ClinicalPalette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Gap.v(2),
                          Text(
                            'Plain-language handout · review before sharing',
                            style: ClinicalText.caption,
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: ClinicalPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ClinicalSpace.md + 2,
                          ClinicalSpace.md,
                          ClinicalSpace.md + 2,
                          ClinicalSpace.md,
                        ),
                        child: SelectableText(
                          widget.text,
                          style: const TextStyle(
                            color: ClinicalPalette.text,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClinicalSpace.md,
                          vertical: ClinicalSpace.sm + 2,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _onCopy(context),
                                icon: const Icon(Icons.copy, size: 14),
                                label: const Text('Copy'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const Gap.h(ClinicalSpace.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _onShare,
                                icon: const Icon(Icons.ios_share, size: 14),
                                label: const Text('Share'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
