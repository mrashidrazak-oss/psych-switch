// MCP handler smoke tests.
//
// Loads the engine from the canonical /content/ tree, builds the
// 18-handler registry, and round-trips one or two payloads through
// each handler. Catches:
//   • registry drift (missing handler)
//   • engine wiring errors
//   • argument-decoding bugs
//   • JSON-encodable output

import 'package:psychswitch_mcp/psychswitch_mcp.dart';
import 'package:test/test.dart';

void main() {
  late ServerContent content;
  late HandlerRegistry handlers;

  setUpAll(() async {
    content = await loadServerContent();
    handlers = buildHandlers(content);
  });

  test('registry has all 18 tools', () {
    final declared = toolDescriptors.map((t) => t['name'] as String).toSet();
    expect(handlers.keys.toSet(), equals(declared));
    expect(handlers.length, equals(18));
  });

  group('drug registry', () {
    test('list_drugs returns >=30 visible drugs', () async {
      final r = await handlers['psychswitch_list_drugs']!(<String, dynamic>{})
          as Map<String, dynamic>;
      expect(r['count'], greaterThanOrEqualTo(30));
    });

    test('list_drugs includeHidden returns the full 40', () async {
      final r = await handlers['psychswitch_list_drugs']!(<String, dynamic>{
        'includeHidden': true,
      }) as Map<String, dynamic>;
      expect(r['count'], equals(40));
    });

    test('get_drug returns sertraline profile', () async {
      final r = await handlers['psychswitch_get_drug']!(<String, dynamic>{
        'drugId': 'sertraline',
      }) as Map<String, dynamic>;
      expect(r['id'], equals('sertraline'));
      expect(r['drugClass'], equals('SSRI'));
    });

    test('get_drug throws ArgumentError on unknown id', () async {
      await expectLater(
        handlers['psychswitch_get_drug']!(
          <String, dynamic>{'drugId': 'not-a-drug'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('switching', () {
    test('list_rules returns 126 reviewed rules', () async {
      final r = await handlers['psychswitch_list_rules']!(<String, dynamic>{})
          as Map<String, dynamic>;
      expect(r['count'], equals(126));
    });

    test('generate_plan ok for sertraline → escitalopram at reference', () async {
      final r = await handlers['psychswitch_generate_plan']!(
        <String, dynamic>{
          'fromDrugId': 'sertraline',
          'fromDoseMg': 100,
          'toDrugId': 'escitalopram',
          'toDoseMg': 10,
        },
      ) as Map<String, dynamic>;
      expect(r['status'], equals('ok'));
      expect(r['dosesMatchReference'], isTrue);
      expect((r['schedule']! as List).isNotEmpty, isTrue);
    });

    test('generate_plan maoi_washout for SSRI → moclobemide', () async {
      final r = await handlers['psychswitch_generate_plan']!(
        <String, dynamic>{
          'fromDrugId': 'sertraline',
          'fromDoseMg': 100,
          'toDrugId': 'moclobemide',
          'toDoseMg': 300,
        },
      ) as Map<String, dynamic>;
      expect(r['status'], equals('maoi_washout'));
      expect(r['washoutDays'], equals(14));
    });

    test('generate_plan clozapine_redirect for olanzapine → clozapine',
        () async {
      final r = await handlers['psychswitch_generate_plan']!(
        <String, dynamic>{
          'fromDrugId': 'olanzapine',
          'fromDoseMg': 20,
          'toDrugId': 'clozapine',
          'toDoseMg': 300,
        },
      ) as Map<String, dynamic>;
      expect(r['status'], equals('clozapine_redirect'));
    });

    test('scale_schedule scales an ok plan', () async {
      final r = await handlers['psychswitch_scale_schedule']!(
        <String, dynamic>{
          'fromDrugId': 'olanzapine',
          'fromDoseMg': 30,
          'toDrugId': 'aripiprazole',
          'toDoseMg': 15,
        },
      ) as Map<String, dynamic>;
      expect(r['mode'], isA<String>());
      expect(r['adapted'], isTrue);
      expect(r['schedule'], isA<List<dynamic>>());
    });
  });

  group('analytics + lookups', () {
    test('dose_equivalent: 100 mg sertraline → fluoxetine = 40 mg', () async {
      final r = await handlers['psychswitch_dose_equivalent']!(
        <String, dynamic>{
          'family': 'fluoxetine',
          'fromDrugId': 'sertraline',
          'fromDoseMg': 100,
          'toDrugId': 'fluoxetine',
        },
      ) as Map<String, dynamic>;
      expect(r['toDoseMg'], equals(40));
    });

    test('predict_ae returns predictions for olanzapine', () async {
      final r = await handlers['psychswitch_predict_ae']!(
        <String, dynamic>{'toDrugId': 'olanzapine'},
      ) as Map<String, dynamic>;
      expect(r['predictions'], isA<List<dynamic>>());
      expect((r['predictions']! as List).isNotEmpty, isTrue);
    });

    test('quantitative_ae returns numbers for olanzapine', () async {
      final r = await handlers['psychswitch_quantitative_ae']!(
        <String, dynamic>{'drugId': 'olanzapine'},
      ) as Map<String, dynamic>;
      expect(r['count'], greaterThan(0));
    });

    test('check_ddi flags fluoxetine + phenelzine as avoid', () async {
      final r = await handlers['psychswitch_check_ddi']!(<String, dynamic>{
        'drugIds': <String>['fluoxetine', 'phenelzine'],
      }) as Map<String, dynamic>;
      expect(r['hitCount'], greaterThan(0));
      final hits = r['hits']! as List<dynamic>;
      expect(
        hits.any((h) => (h as Map<String, dynamic>)['severity'] == 'avoid'),
        isTrue,
      );
    });

    test('compute_score returns a 0-100 number for an ok plan', () async {
      final r = await handlers['psychswitch_compute_score']!(
        <String, dynamic>{
          'fromDrugId': 'sertraline',
          'fromDoseMg': 100,
          'toDrugId': 'escitalopram',
          'toDoseMg': 10,
        },
      ) as Map<String, dynamic>;
      expect(r['total'], isA<int>());
      expect(r['total'], inInclusiveRange(0, 100));
      expect(r['band'], isA<String>());
    });

    test('overlap_intensity returns a tier + flags', () async {
      final r = await handlers['psychswitch_overlap_intensity']!(
        <String, dynamic>{
          'fromDrugId': 'sertraline',
          'fromDoseMg': 100,
          'toDrugId': 'escitalopram',
          'toDoseMg': 10,
        },
      ) as Map<String, dynamic>;
      expect(r['tier'], isA<String>());
      expect(r['flags'], isA<List<dynamic>>());
    });
  });

  group('search + glossary', () {
    test('search finds olanzapine', () async {
      final r = await handlers['psychswitch_search']!(<String, dynamic>{
        'query': 'olanzapine',
      }) as Map<String, dynamic>;
      final drugs = r['drugs']! as List<dynamic>;
      expect(drugs, isNotEmpty);
    });

    test('lookup_glossary finds QTc', () async {
      final r = await handlers['psychswitch_lookup_glossary']!(
        <String, dynamic>{'term': 'QTc'},
      ) as Map<String, dynamic>;
      expect(r['found'], isTrue);
    });

    test('lookup_glossary not-found returns found:false', () async {
      final r = await handlers['psychswitch_lookup_glossary']!(
        <String, dynamic>{'term': 'not-a-real-term'},
      ) as Map<String, dynamic>;
      expect(r['found'], isFalse);
    });
  });

  group('citations + errata', () {
    test('get_citation returns the curated paraphrase entry', () async {
      final r = await handlers['psychswitch_get_citation']!(
        <String, dynamic>{'key': 'maudsley15_ch3_p369_table_3_7'},
      ) as Map<String, dynamic>;
      expect(r['key'], equals('maudsley15_ch3_p369_table_3_7'));
      expect(r['paraphrase'], isNotNull);
    });

    test('list_errata returns the seeded entries', () async {
      final r = await handlers['psychswitch_list_errata']!(
        <String, dynamic>{},
      ) as Map<String, dynamic>;
      expect(r['count'], greaterThan(0));
    });
  });

  group('patient context + specialty + cost', () {
    test('context_warnings flags lithium + severe CKD', () async {
      final r = await handlers['psychswitch_context_warnings']!(
        <String, dynamic>{
          'drugId': 'lithium',
          'context': <String, dynamic>{'renal': 'severe'},
        },
      ) as Map<String, dynamic>;
      final warnings = r['warnings']! as List<dynamic>;
      expect(
        warnings.any(
          (w) => (w as Map<String, dynamic>)['severity'] == 'danger',
        ),
        isTrue,
      );
    });

    test('assess_specialty returns geriatric recs for age=80', () async {
      final r = await handlers['psychswitch_assess_specialty']!(
        <String, dynamic>{
          'fromDrugId': 'sertraline',
          'toDrugId': 'mirtazapine',
          'context': <String, dynamic>{'ageYears': 80, 'sex': 'male'},
        },
      ) as Map<String, dynamic>;
      final applicable = (r['applicable']! as List<dynamic>).cast<String>();
      expect(applicable, contains('geriatric'));
    });

    test('cost returns Malaysian price for sertraline', () async {
      final r = await handlers['psychswitch_cost']!(<String, dynamic>{
        'drugId': 'sertraline',
      }) as Map<String, dynamic>;
      expect(r['found'], isTrue);
      expect(r['monthlyCostMyr'], isA<num>());
      expect(r['formatted'], isA<String>());
    });
  });
}
