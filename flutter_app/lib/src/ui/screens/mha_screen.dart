// Mental Health Act 2001 (Malaysia) — quick reference.
//
// Bedside reference for the most commonly invoked sections, durations,
// and admission pathways under MHA 2001 (Act 615) and its Regulations
// 2010. Authoring source: Federal Gazette + MOH Mental Health Services
// Operational Policy 2011. Verify the gazette before formal use.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';

class MhaScreen extends StatelessWidget {
  const MhaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MHA 2001 (MY)'),
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
          children: const <Widget>[
            _Hero(),
            SizedBox(height: ClinicalSpace.lg),
            _SectionGroup(
              title: 'Voluntary admission',
              entries: <_MhaEntry>[
                _MhaEntry(
                  section: 'S. 8',
                  title: 'Voluntary patient',
                  body: 'Any person aged ≥ 16 may apply in writing for '
                      'voluntary admission. May be discharged at any '
                      'time. If treating psychiatrist considers '
                      'compulsory detention necessary, switch to S. 10 '
                      "with the Board's authority.",
                ),
              ],
            ),
            SizedBox(height: ClinicalSpace.md),
            _SectionGroup(
              title: 'Involuntary / compulsory admission',
              entries: <_MhaEntry>[
                _MhaEntry(
                  section: 'S. 10',
                  title: 'Admission on application of relative',
                  body: 'Application by a relative + supporting medical '
                      'recommendation from a registered medical '
                      'practitioner. Initial duration: 1 month. '
                      'Renewable by the Visiting Psychiatrist '
                      'thereafter (3 → 6 → 12 months).',
                ),
                _MhaEntry(
                  section: 'S. 11',
                  title: 'Emergency admission by relative',
                  body: 'When awaiting S. 10 paperwork is impractical. '
                      'Medical recommendation + signature of a '
                      'relative. Valid up to 72 hours; convert to S. 10 '
                      'within that window or discharge.',
                ),
                _MhaEntry(
                  section: 'S. 12',
                  title: 'Admission of person found in public place',
                  body: 'Police may convey to a psychiatric facility a '
                      'person who appears mentally disordered and a '
                      'danger to self or others. Initial assessment '
                      'window: 24 hours; further detention requires '
                      'medical certification + S. 10/11 conversion.',
                ),
                _MhaEntry(
                  section: 'S. 13',
                  title: 'Admission by Court',
                  body: 'Court-ordered admission of an accused who is '
                      'mentally disordered. Duration: indefinite, '
                      'reviewed by the Board.',
                ),
              ],
            ),
            SizedBox(height: ClinicalSpace.md),
            _SectionGroup(
              title: 'Treatment without consent',
              entries: <_MhaEntry>[
                _MhaEntry(
                  section: 'S. 77',
                  title: 'Consent to ECT or psychosurgery',
                  body: 'Informed written consent of the patient + '
                      'second-opinion from another psychiatrist + '
                      'authority of the Board. In genuine emergencies, '
                      'the Board may be approached retrospectively.',
                ),
                _MhaEntry(
                  section: 'S. 78',
                  title: 'Emergency treatment',
                  body: 'Treatment may be given without consent where '
                      'immediately necessary to save life or prevent '
                      'serious deterioration. Document the clinical '
                      'urgency clearly.',
                ),
              ],
            ),
            SizedBox(height: ClinicalSpace.md),
            _SectionGroup(
              title: 'Discharge & review',
              entries: <_MhaEntry>[
                _MhaEntry(
                  section: 'S. 14',
                  title: 'Discharge of detained patient',
                  body: 'Detained patient may be discharged by the '
                      'treating psychiatrist when mentally fit. '
                      'Relatives may apply to the Board for review of '
                      'continuing detention.',
                ),
                _MhaEntry(
                  section: 'S. 19',
                  title: 'Mental Health Review Tribunal',
                  body: 'Reviews continuing detention. Patient or '
                      'representative may petition. Tribunal may '
                      'discharge, vary, or maintain the detention.',
                ),
              ],
            ),
            SizedBox(height: ClinicalSpace.md),
            _SectionGroup(
              title: 'Common documentation pearls',
              entries: <_MhaEntry>[
                _MhaEntry(
                  section: 'Forms',
                  title: 'Required forms',
                  body: 'Form 2 (medical recommendation), Form 3 '
                      '(application by relative), Form 4 (emergency '
                      'admission), Form 6 (continuation of detention). '
                      'Hospital pharmacy / records office holds the '
                      'current MOH templates.',
                ),
                _MhaEntry(
                  section: 'Renewal',
                  title: 'Renewal cadence',
                  body: 'S. 10 detention: 1 → 3 → 6 → 12 months. '
                      'Beyond 12 months requires re-recommendation by '
                      'two psychiatrists.',
                ),
                _MhaEntry(
                  section: 'Capacity',
                  title: 'Capacity assessment',
                  body: 'MHA 2001 does not codify capacity tests. Use '
                      'the four-limb capacity framework (understand, '
                      'retain, weigh, communicate) and document each '
                      'limb when assessing treatment refusal.',
                ),
              ],
            ),
            SizedBox(height: ClinicalSpace.lg),
            _Disclaimer(),
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
            label: 'Malaysia',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Mental Health Act 2001 · quick reference',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneSkyInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Most-used sections, durations, and admission pathways at a '
            'glance. Verify against the current gazette before any '
            'formal admission paperwork — content reflects MHA 2001 '
            '(Act 615) and the Regulations 2010.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSkyInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MhaEntry {
  const _MhaEntry({
    required this.section,
    required this.title,
    required this.body,
  });

  final String section;
  final String title;
  final String body;
}

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({required this.title, required this.entries});
  final String title;
  final List<_MhaEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: ClinicalSpace.xs),
          child: Text(title, style: ClinicalText.subtitle),
        ),
        const SizedBox(height: ClinicalSpace.sm),
        SquircleCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (var i = 0; i < entries.length; i++) ...<Widget>[
                if (i > 0)
                  const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: ClinicalSpace.lg,
                  ),
                _EntryRow(entry: entries[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final _MhaEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg,
        ClinicalSpace.md,
        ClinicalSpace.lg,
        ClinicalSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.sm + 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: ClinicalPalette.toneSky,
                  borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                ),
                child: Text(
                  entry.section,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ClinicalPalette.toneSkyInk,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.sm + 2),
              Expanded(
                child: Text(
                  entry.title,
                  style: ClinicalText.subtitle
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.body,
            style: ClinicalText.body.copyWith(height: 1.55),
          ),
        ],
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
          const Icon(Icons.gavel_outlined,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Clinical summary only — always cross-check the current '
              'Federal Gazette, the MOH Operational Policy, and your '
              "hospital's standing orders before formal application "
              'of a section.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
