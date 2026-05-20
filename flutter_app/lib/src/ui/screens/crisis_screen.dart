// Crisis lifelines + Stanley-Brown safety plan.
//
// One-tap call buttons for Malaysian crisis services, plus a 6-step
// Stanley-Brown safety plan the clinician fills in collaboratively
// with the patient. The plan stays on-device — paste the resulting
// summary into the patient's chart or hand the patient a print-out.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisScreen extends StatefulWidget {
  const CrisisScreen({super.key});

  @override
  State<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends State<CrisisScreen> {
  final _warningCtl = TextEditingController();
  final _copingCtl = TextEditingController();
  final _socialCtl = TextEditingController();
  final _supportCtl = TextEditingController();
  final _professionalCtl = TextEditingController();
  final _meansCtl = TextEditingController();

  @override
  void dispose() {
    _warningCtl.dispose();
    _copingCtl.dispose();
    _socialCtl.dispose();
    _supportCtl.dispose();
    _professionalCtl.dispose();
    _meansCtl.dispose();
    super.dispose();
  }

  String _safetyPlanText() {
    String fill(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? '   —' : '   $t';
    }
    final lines = <String>[
      'STANLEY-BROWN SAFETY PLAN',
      '',
      '1. Warning signs:',
      fill(_warningCtl),
      '',
      '2. Internal coping strategies:',
      fill(_copingCtl),
      '',
      '3. Social settings and people that provide distraction:',
      fill(_socialCtl),
      '',
      '4. People to ask for help:',
      fill(_supportCtl),
      '',
      '5. Professionals / agencies to contact in crisis:',
      fill(_professionalCtl),
      '',
      '6. Means restriction — make the environment safe:',
      fill(_meansCtl),
      '',
      'Crisis lifelines (Malaysia):',
      ' · Talian Kasih — 15999',
      ' · Befrienders KL — 03-7627-2929',
      ' · MENTARI (MOH) — 03-2935-9935',
      ' · Emergency — 999',
    ];
    return lines.join('\n');
  }

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      unawaited(hapticsConfirm());
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisis & safety plan'),
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
            _LifelineCard(
              tone: ClinicalPalette.toneRose,
              ink: ClinicalPalette.toneRoseInk,
              icon: Icons.emergency_rounded,
              name: 'Emergency',
              number: '999',
              note: 'Immediate danger to life · police / ambulance',
              onCall: () => _dial('999'),
            ),
            const SizedBox(height: ClinicalSpace.sm + 2),
            _LifelineCard(
              tone: ClinicalPalette.tonePeach,
              ink: ClinicalPalette.tonePeachInk,
              icon: Icons.support_agent_rounded,
              name: 'Talian Kasih',
              number: '15999',
              note: 'KPWKM helpline · 24-hour · all languages',
              onCall: () => _dial('15999'),
            ),
            const SizedBox(height: ClinicalSpace.sm + 2),
            _LifelineCard(
              tone: ClinicalPalette.toneLavender,
              ink: ClinicalPalette.toneLavenderInk,
              icon: Icons.volunteer_activism_outlined,
              name: 'Befrienders KL',
              number: '03-7627-2929',
              note: 'Emotional support · 24-hour · English & BM',
              onCall: () => _dial('0376272929'),
            ),
            const SizedBox(height: ClinicalSpace.sm + 2),
            _LifelineCard(
              tone: ClinicalPalette.toneSky,
              ink: ClinicalPalette.toneSkyInk,
              icon: Icons.local_hospital_outlined,
              name: 'MENTARI (MOH)',
              number: '03-2935-9935',
              note: 'Ministry of Health mental health line · Mon–Fri',
              onCall: () => _dial('0329359935'),
            ),
            const SizedBox(height: ClinicalSpace.lg + 4),
            const Text(
              'Stanley-Brown safety plan',
              style: ClinicalText.title,
            ),
            const SizedBox(height: 2),
            Text(
              'Fill collaboratively with the patient. The "Copy" pill '
              'drops a paste-ready text block.',
              style: ClinicalText.caption.copyWith(height: 1.5),
            ),
            const SizedBox(height: ClinicalSpace.md),
            _PlanField(
              eyebrow: '1. Warning signs',
              hint: 'Thoughts, images, mood, situation, behaviour…',
              controller: _warningCtl,
            ),
            _PlanField(
              eyebrow: '2. Internal coping strategies',
              hint: 'Things they can do alone to take their mind off…',
              controller: _copingCtl,
            ),
            _PlanField(
              eyebrow: '3. People & settings that distract',
              hint: 'Place / activity / people (no support sought)…',
              controller: _socialCtl,
            ),
            _PlanField(
              eyebrow: '4. People to ask for help',
              hint: 'Name + number of family / friends to call…',
              controller: _supportCtl,
            ),
            _PlanField(
              eyebrow: '5. Professionals & agencies',
              hint: 'Clinician / clinic / crisis line numbers…',
              controller: _professionalCtl,
            ),
            _PlanField(
              eyebrow: '6. Means restriction',
              hint: 'How to make the environment safer (lock medications, '
                  'give car keys to family, etc.)',
              controller: _meansCtl,
            ),
            const SizedBox(height: ClinicalSpace.md),
            PillButton(
              label: 'Copy safety plan',
              icon: Icons.copy_rounded,
              expanded: true,
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: _safetyPlanText()),
                );
                unawaited(hapticsConfirm());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Safety plan copied')),
                );
              },
            ),
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
      tone: ClinicalPalette.tonePeach,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Crisis · safety',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.tonePeachInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'One tap to dial · one paragraph for the chart',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.tonePeachInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Malaysian crisis lifelines plus the six-step '
            'Stanley-Brown safety plan, fillable in the room with '
            'the patient.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.tonePeachInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifelineCard extends StatelessWidget {
  const _LifelineCard({
    required this.tone,
    required this.ink,
    required this.icon,
    required this.name,
    required this.number,
    required this.note,
    required this.onCall,
  });

  final Color tone;
  final Color ink;
  final IconData icon;
  final String name;
  final String number;
  final String note;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: tone,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      onTap: onCall,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ink),
          ),
          const SizedBox(width: ClinicalSpace.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: ClinicalText.caption.copyWith(
                    color: ink.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _PlanField extends StatelessWidget {
  const _PlanField({
    required this.eyebrow,
    required this.hint,
    required this.controller,
  });

  final String eyebrow;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ClinicalSpace.md),
      child: SquircleCard(
        padding: const EdgeInsets.all(ClinicalSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(eyebrow.toUpperCase(), style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            TextField(
              controller: controller,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: ClinicalText.body.copyWith(
                  color: ClinicalPalette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
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
          const Icon(Icons.lock_outline,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Safety plan stays on this device — nothing is uploaded. '
              'Copy + paste into the chart, then clear when done.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
