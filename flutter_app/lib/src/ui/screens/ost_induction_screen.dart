// Opioid-substitution induction — pick agent, enter COWS + context,
// see the day-1 protocol with the safety gate.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/ost_induction.dart';

class OstInductionScreen extends StatefulWidget {
  const OstInductionScreen({super.key});

  @override
  State<OstInductionScreen> createState() =>
      _OstInductionScreenState();
}

class _OstInductionScreenState extends State<OstInductionScreen> {
  OstAgent _agent = OstAgent.buprenorphine;
  final _cowsCtrl = TextEditingController(text: '12');
  bool _longActing = false;
  bool _lowTol = false;

  @override
  void dispose() {
    _cowsCtrl.dispose();
    super.dispose();
  }

  int get _cows {
    final v = int.tryParse(_cowsCtrl.text.trim());
    if (v == null || v < 0) return 0;
    return v > 48 ? 48 : v;
  }

  void _set(VoidCallback fn) {
    setState(fn);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final plan = buildOstPlan(OstInput(
      agent: _agent,
      cowsScore: _cows,
      longActingOpioidOrFentanyl: _longActing,
      lowTolerance: _lowTol,
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text('OST induction'),
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
            const Text('AGENT', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Row(
              children: <Widget>[
                for (final a in OstAgent.values) ...<Widget>[
                  Expanded(
                    child: _Seg(
                      label: a.label,
                      selected: _agent == a,
                      onTap: () => _set(() => _agent = a),
                    ),
                  ),
                  if (a != OstAgent.values.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            SquircleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('LATEST COWS SCORE',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  TextField(
                    controller: _cowsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      hintText: 'e.g. 14',
                      suffixText: '/ 48',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  Text(
                    'Buprenorphine needs objective withdrawal '
                    '(COWS ≥ 12) before the first dose — the '
                    'precipitated-withdrawal safeguard.',
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClinicalSpace.md),
            _Toggle(
              label: 'Long-acting opioid / fentanyl on board',
              value: _longActing,
              onTap: () => _set(() => _longActing = !_longActing),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Low / uncertain tolerance',
              value: _lowTol,
              onTap: () => _set(() => _lowTol = !_lowTol),
            ),
            const SizedBox(height: ClinicalSpace.lg),
            _PlanCard(plan: plan),
            const SizedBox(height: ClinicalSpace.md),
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
      tone: ClinicalPalette.toneSky,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'COWS-gated induction',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Day-1 OST without the classic errors',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneSkyInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Buprenorphine: the COWS ≥ 12 gate against precipitated '
            'withdrawal. Methadone: "start low, go slow" against '
            'day-3 accumulation deaths. UK Orange Book / NICE / '
            'Maudsley 15e.',
            style: ClinicalText.body.copyWith(
              color:
                  ClinicalPalette.toneSkyInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected
                  ? ClinicalPalette.ctaText
                  : ClinicalPalette.text,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.all(ClinicalSpace.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 1.2,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: ClinicalPalette.cta)
                    : null,
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: value
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final OstPlan plan;

  @override
  Widget build(BuildContext context) {
    final ok = plan.canStartNow;
    return SquircleCard(
      tone: ok ? ClinicalPalette.toneMint : ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                ok ? Icons.check_circle_outline : Icons.timer_outlined,
                color: ok
                    ? ClinicalPalette.toneMintInk
                    : ClinicalPalette.toneSandInk,
              ),
              const SizedBox(width: ClinicalSpace.sm),
              Expanded(
                child: Text(
                  plan.headline,
                  style: ClinicalText.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ok
                        ? ClinicalPalette.toneMintInk
                        : ClinicalPalette.toneSandInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          _Block(
            title: 'STEPS',
            items: plan.steps,
            ink: ok
                ? ClinicalPalette.toneMintInk
                : ClinicalPalette.toneSandInk,
            icon: Icons.arrow_right_alt,
          ),
          _Block(
            title: 'CAUTIONS',
            items: plan.cautions,
            ink: ok
                ? ClinicalPalette.toneMintInk
                : ClinicalPalette.toneSandInk,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          PillButton(
            label: 'Copy protocol',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: plan.clipboardSummary()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              showCopiedToast(context, label: 'Protocol');
            },
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.items,
    required this.ink,
    required this.icon,
  });

  final String title;
  final List<String> items;
  final Color ink;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: ClinicalText.eyebrow.copyWith(color: ink),
        ),
        const SizedBox(height: ClinicalSpace.sm),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(icon, size: 14, color: ink),
                ),
                const SizedBox(width: ClinicalSpace.sm + 2),
                Expanded(
                  child: Text(
                    it,
                    style: ClinicalText.body.copyWith(
                      color: ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: ClinicalSpace.sm),
      ],
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
              'Specialist addiction-medicine context required. '
              'Confirm recent use, supervise consumption during '
              'induction, and follow your local OST protocol.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
