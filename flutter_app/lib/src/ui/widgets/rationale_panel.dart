// Rationale panel — explains WHY this particular strategy was chosen
// for this drug pair. Collapses long clinical explanations behind a
// "Read more" toggle so the schedule stays the focal point.
//
// RN parity: `components/RationalePanel.tsx`.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';

class RationalePanel extends StatefulWidget {
  const RationalePanel({required this.rationale, super.key});

  final String rationale;

  static const int _previewCharLimit = 180;

  @override
  State<RationalePanel> createState() => _RationalePanelState();
}

class _RationalePanelState extends State<RationalePanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cleaned = widget.rationale
        .replaceAll(RegExp(r'\s*PENDING_CLINICAL_REVIEW\.?\s*$'), '')
        .trim();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final isLong = cleaned.length > RationalePanel._previewCharLimit;
    final preview = isLong
        ? '${cleaned.substring(0, RationalePanel._previewCharLimit).trimRight()}…'
        : cleaned;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg - 2,
        AppSpace.md + 2,
        AppSpace.lg - 2,
        AppSpace.lg - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('WHY THIS STRATEGY', style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs + 2),
          Text(
            _expanded || !isLong ? cleaned : preview,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (isLong) ...<Widget>[
            const Gap.v(AppSpace.sm),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
