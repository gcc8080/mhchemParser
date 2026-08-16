import 'dart:convert';
import 'dart:io';

import 'package:mhchem_parser/mhchem_parser.dart';
import 'package:test/test.dart';

MhchemMode _parseMode(String value) {
  return switch (value) {
    'tex' => MhchemMode.tex,
    'ce' => MhchemMode.ce,
    'pu' => MhchemMode.pu,
    _ => throw ArgumentError.value(value, 'value', 'Unknown fixture mode.'),
  };
}

void main() {
  final fixture = jsonDecode(
    File(
      'test/fixtures/mhchem_parser_4_2_2.json',
    ).readAsStringSync(),
  ) as Map<String, dynamic>;
  final counts = fixture['counts'] as Map<String, dynamic>;
  final cases = (fixture['cases'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  test('canonical corpus identity and counts are complete', () {
    expect(fixture['schemaVersion'], 1);
    expect((fixture['source'] as Map<String, dynamic>)['version'], '4.2.2');
    expect(
      (fixture['source'] as Map<String, dynamic>)['commit'],
      'acaf5adb97a08deb234e0a8d62c807c17ee650d6',
    );
    expect(counts, containsPair('total', 117));
    expect(counts, containsPair('tex', 1));
    expect(counts, containsPair('ce', 95));
    expect(counts, containsPair('pu', 21));
    expect(cases, hasLength(117));
    expect(cases.map((entry) => entry['id']).toSet(), hasLength(117));
  });

  group('mhchemParser 4.2.2 canonical conversion', () {
    for (final testCase in cases) {
      final id = testCase['id']! as String;
      final modeName = testCase['mode']! as String;
      final input = testCase['input']! as String;
      final expected = testCase['expected']! as String;

      test('$id ($modeName)', () {
        expect(
          MhchemParser.convert(input, mode: _parseMode(modeName)),
          expected,
          reason:
              'Canonical case $id failed for mode $modeName and input $input',
        );
      });
    }
  });
}
