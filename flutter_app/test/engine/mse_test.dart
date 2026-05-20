// Tests for the MSE narrative generator.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/mse.dart';

void main() {
  test('all 11 domains registered in canonical order', () {
    expect(kMseDomains.length, 11);
    expect(kMseDomains.first.id, 'appearance');
    expect(kMseDomains.last.id, 'judgement');
  });

  test('empty picks → placeholder narrative', () {
    expect(generateMseNarrative(picks: const <String, String>{}),
        'MSE pending.');
  });

  test('single domain pick produces single sentence', () {
    final out = generateMseNarrative(picks: <String, String>{
      'appearance': 'wellgroomed',
    });
    expect(out, contains('well-groomed'));
  });

  test('multi-domain picks concatenate in canonical order', () {
    final out = generateMseNarrative(picks: <String, String>{
      'appearance': 'wellgroomed',
      'mood': 'low',
      'affect': 'congruent',
    });
    final apIdx = out.indexOf('well-groomed');
    final mdIdx = out.indexOf('low and sad');
    final afIdx = out.indexOf('reactive and congruent');
    expect(apIdx < mdIdx, isTrue);
    expect(mdIdx < afIdx, isTrue);
  });

  test('free-text overlay is appended in-sentence', () {
    final out = generateMseNarrative(
      picks: <String, String>{'thoughtcontent': 'suicidal'},
      freeText: <String, String>{
        'thoughtcontent': 'with passive ideation, no plan or intent',
      },
    );
    expect(out, contains('suicidal ideation — with passive ideation'));
  });

  test('unknown anchor id falls back to first anchor', () {
    final out = generateMseNarrative(picks: <String, String>{
      'mood': 'completely-made-up',
    });
    // Should still produce a mood sentence, not crash.
    expect(out, contains('Mood'));
  });

  test('every anchor prose ends with a full stop', () {
    for (final d in kMseDomains) {
      for (final a in d.anchors) {
        expect(a.prose.endsWith('.'), isTrue,
            reason: 'Anchor ${d.id}/${a.id} prose missing period');
      }
    }
  });
}
