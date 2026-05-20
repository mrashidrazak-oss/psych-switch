// Mental State Examination narrative generator.
//
// The clinician picks one anchor per domain (appearance, behaviour,
// speech, mood, affect, thought-form, thought-content, perception,
// cognition, insight, judgement) and the engine emits a paste-ready
// paragraph in standard MSE prose. Optional free-text per domain
// extends a chosen anchor with patient-specific detail.
//
// Anchors are clinician-flavoured — they mirror the phrasing one
// would actually write in a clinical note rather than DSM jargon.

class MseDomain {
  const MseDomain({
    required this.id,
    required this.label,
    required this.eyebrow,
    required this.anchors,
  });

  final String id;
  final String label;
  final String eyebrow;

  /// Each anchor is the prose snippet inserted into the narrative.
  /// First-token capitalisation is handled by the generator.
  final List<MseAnchor> anchors;
}

class MseAnchor {
  const MseAnchor({required this.id, required this.label, required this.prose});

  /// Stable id for the anchor (used as map value).
  final String id;

  /// Short label shown on the chip.
  final String label;

  /// Prose snippet inserted into the narrative.
  final String prose;
}

/// Build the narrative paragraph. Picks are domain-id → anchor-id.
/// Free-text overlays are domain-id → free-text (appended to the
/// anchor's prose).
String generateMseNarrative({
  required Map<String, String> picks,
  Map<String, String>? freeText,
}) {
  final ft = freeText ?? const <String, String>{};
  final sentences = <String>[];
  for (final domain in kMseDomains) {
    final pickedId = picks[domain.id];
    if (pickedId == null) continue;
    final anchor = domain.anchors.firstWhere(
      (a) => a.id == pickedId,
      orElse: () => domain.anchors.first,
    );
    var prose = anchor.prose;
    final overlay = ft[domain.id]?.trim();
    if (overlay != null && overlay.isNotEmpty) {
      prose = prose.endsWith('.') ? prose.substring(0, prose.length - 1) : prose;
      prose = '$prose — $overlay.';
    }
    sentences.add(prose);
  }
  if (sentences.isEmpty) {
    return 'MSE pending.';
  }
  return sentences.join(' ');
}

const List<MseDomain> kMseDomains = <MseDomain>[
  MseDomain(
    id: 'appearance',
    label: 'Appearance',
    eyebrow: 'APPEARANCE',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'wellgroomed',
        label: 'Well-groomed',
        prose: 'Patient was well-groomed and appropriately dressed.',
      ),
      MseAnchor(
        id: 'casual',
        label: 'Casual / unremarkable',
        prose: 'Appearance was casual and unremarkable.',
      ),
      MseAnchor(
        id: 'dishevelled',
        label: 'Dishevelled',
        prose: 'Patient appeared dishevelled with poor self-care.',
      ),
      MseAnchor(
        id: 'bizarre',
        label: 'Bizarre / odd',
        prose: 'Patient presented with bizarre attire suggesting '
            'eccentric self-presentation.',
      ),
    ],
  ),
  MseDomain(
    id: 'behaviour',
    label: 'Behaviour',
    eyebrow: 'BEHAVIOUR',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'cooperative',
        label: 'Cooperative · good eye contact',
        prose: 'Behaviour was cooperative with appropriate eye contact.',
      ),
      MseAnchor(
        id: 'guarded',
        label: 'Guarded',
        prose: 'Patient was guarded, with limited eye contact and brief '
            'responses.',
      ),
      MseAnchor(
        id: 'agitated',
        label: 'Agitated · restless',
        prose: 'Patient was visibly agitated and restless during the '
            'interview.',
      ),
      MseAnchor(
        id: 'retarded',
        label: 'Psychomotor retardation',
        prose: 'Psychomotor activity was reduced with slowed responses.',
      ),
      MseAnchor(
        id: 'hostile',
        label: 'Hostile · uncooperative',
        prose: 'Patient was hostile and uncooperative.',
      ),
    ],
  ),
  MseDomain(
    id: 'speech',
    label: 'Speech',
    eyebrow: 'SPEECH',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'normal',
        label: 'Normal rate · rhythm · volume',
        prose: 'Speech was of normal rate, rhythm, and volume.',
      ),
      MseAnchor(
        id: 'pressured',
        label: 'Pressured · rapid',
        prose: 'Speech was pressured and rapid, with reduced ability to '
            'interrupt.',
      ),
      MseAnchor(
        id: 'slowed',
        label: 'Slowed · soft',
        prose: 'Speech was slowed and soft in volume.',
      ),
      MseAnchor(
        id: 'monosyllabic',
        label: 'Monosyllabic',
        prose: 'Speech was monosyllabic, with limited spontaneous '
            'elaboration.',
      ),
    ],
  ),
  MseDomain(
    id: 'mood',
    label: 'Mood (subjective)',
    eyebrow: 'MOOD',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'euthymic',
        label: 'Euthymic',
        prose: 'Mood was described as euthymic.',
      ),
      MseAnchor(
        id: 'low',
        label: 'Low / sad',
        prose: 'Mood was reported as low and sad.',
      ),
      MseAnchor(
        id: 'anxious',
        label: 'Anxious',
        prose: 'Mood was reported as anxious.',
      ),
      MseAnchor(
        id: 'elevated',
        label: 'Elevated',
        prose: 'Mood was reported as elevated.',
      ),
      MseAnchor(
        id: 'irritable',
        label: 'Irritable',
        prose: 'Mood was reported as irritable.',
      ),
    ],
  ),
  MseDomain(
    id: 'affect',
    label: 'Affect (observed)',
    eyebrow: 'AFFECT',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'congruent',
        label: 'Reactive · congruent',
        prose: 'Affect was reactive and congruent with stated mood.',
      ),
      MseAnchor(
        id: 'blunted',
        label: 'Blunted',
        prose: 'Affect was blunted with reduced emotional range.',
      ),
      MseAnchor(
        id: 'flat',
        label: 'Flat',
        prose: 'Affect was flat with little observable variation.',
      ),
      MseAnchor(
        id: 'labile',
        label: 'Labile',
        prose: 'Affect was labile with rapid shifts in expression.',
      ),
      MseAnchor(
        id: 'incongruent',
        label: 'Incongruent',
        prose: 'Affect was incongruent with the content discussed.',
      ),
    ],
  ),
  MseDomain(
    id: 'thoughtform',
    label: 'Thought form',
    eyebrow: 'THOUGHT FORM',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'linear',
        label: 'Linear · goal-directed',
        prose: 'Thought form was linear and goal-directed.',
      ),
      MseAnchor(
        id: 'tangential',
        label: 'Tangential',
        prose: 'Thought form was tangential with frequent off-topic '
            'tangents.',
      ),
      MseAnchor(
        id: 'circumstantial',
        label: 'Circumstantial',
        prose: 'Thought form was circumstantial with excessive detail '
            'before reaching the point.',
      ),
      MseAnchor(
        id: 'flight',
        label: 'Flight of ideas',
        prose: 'Thought form demonstrated flight of ideas.',
      ),
      MseAnchor(
        id: 'loose',
        label: 'Loose associations',
        prose: 'Thought form was disorganised with loose associations.',
      ),
      MseAnchor(
        id: 'blocked',
        label: 'Thought blocking',
        prose: 'Thought form showed episodes of thought blocking.',
      ),
    ],
  ),
  MseDomain(
    id: 'thoughtcontent',
    label: 'Thought content',
    eyebrow: 'THOUGHT CONTENT',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'unremarkable',
        label: 'Unremarkable',
        prose: 'Thought content was unremarkable, with no evidence of '
            'delusions, suicidality, or violent ideation.',
      ),
      MseAnchor(
        id: 'preoccupied',
        label: 'Preoccupations only',
        prose: 'Thought content showed preoccupations without frank '
            'delusional thinking.',
      ),
      MseAnchor(
        id: 'delusions_persecutory',
        label: 'Persecutory delusions',
        prose: 'Thought content included persecutory delusional ideas.',
      ),
      MseAnchor(
        id: 'delusions_grandiose',
        label: 'Grandiose delusions',
        prose: 'Thought content included grandiose delusional ideas.',
      ),
      MseAnchor(
        id: 'suicidal',
        label: 'Suicidal ideation',
        prose: 'Thought content was notable for suicidal ideation.',
      ),
      MseAnchor(
        id: 'homicidal',
        label: 'Homicidal ideation',
        prose: 'Thought content was notable for homicidal ideation.',
      ),
    ],
  ),
  MseDomain(
    id: 'perception',
    label: 'Perception',
    eyebrow: 'PERCEPTION',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'none',
        label: 'No abnormality',
        prose: 'No perceptual abnormality was elicited.',
      ),
      MseAnchor(
        id: 'auditory',
        label: 'Auditory hallucinations',
        prose: 'Auditory hallucinations were reported.',
      ),
      MseAnchor(
        id: 'visual',
        label: 'Visual hallucinations',
        prose: 'Visual hallucinations were reported.',
      ),
      MseAnchor(
        id: 'tactile',
        label: 'Tactile hallucinations',
        prose: 'Tactile hallucinations were reported.',
      ),
      MseAnchor(
        id: 'derealisation',
        label: 'Derealisation / depersonalisation',
        prose: 'Patient reported derealisation and / or '
            'depersonalisation experiences.',
      ),
    ],
  ),
  MseDomain(
    id: 'cognition',
    label: 'Cognition',
    eyebrow: 'COGNITION',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'grossly_intact',
        label: 'Grossly intact',
        prose: 'Cognition appeared grossly intact, oriented to time, '
            'place, and person.',
      ),
      MseAnchor(
        id: 'mild_impairment',
        label: 'Mild impairment',
        prose: 'Cognition showed mild impairment in attention or '
            'short-term recall.',
      ),
      MseAnchor(
        id: 'moderate_impairment',
        label: 'Moderate impairment',
        prose: 'Cognition was significantly impaired, with deficits '
            'in orientation and / or memory.',
      ),
    ],
  ),
  MseDomain(
    id: 'insight',
    label: 'Insight',
    eyebrow: 'INSIGHT',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'good',
        label: 'Good',
        prose: 'Insight was good — patient acknowledges symptoms, '
            'recognises their illness, and accepts treatment.',
      ),
      MseAnchor(
        id: 'partial',
        label: 'Partial',
        prose: 'Insight was partial — acknowledges some symptoms but '
            'incomplete acceptance of illness or treatment need.',
      ),
      MseAnchor(
        id: 'poor',
        label: 'Poor',
        prose: 'Insight was poor — patient does not believe they are '
            'unwell or in need of treatment.',
      ),
    ],
  ),
  MseDomain(
    id: 'judgement',
    label: 'Judgement',
    eyebrow: 'JUDGEMENT',
    anchors: <MseAnchor>[
      MseAnchor(
        id: 'intact',
        label: 'Intact',
        prose: 'Judgement was intact during interview.',
      ),
      MseAnchor(
        id: 'mildly_impaired',
        label: 'Mildly impaired',
        prose: 'Judgement was mildly impaired with limited risk '
            'appreciation.',
      ),
      MseAnchor(
        id: 'impaired',
        label: 'Impaired',
        prose: 'Judgement was impaired, with poor appreciation of risk '
            'and consequences.',
      ),
    ],
  ),
];

/// Domain id → ordered domain for lookup.
MseDomain? mseDomainById(String id) {
  for (final d in kMseDomains) {
    if (d.id == id) return d;
  }
  return null;
}
