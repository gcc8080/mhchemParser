import 'package:mhchem_parser/mhchem_parser.dart';
import 'package:test/test.dart';

String _legacyToTex(String input, String type) {
  // ignore: deprecated_member_use_from_same_package
  return MhchemParser.toTex(input, type);
}

void main() {
  group('version metadata', () {
    test('separates the Dart release from upstream compatibility', () {
      expect(MhchemParser.packageVersion, '0.1.0');
      expect(MhchemParser.upstreamVersion, '4.2.2');
      expect(
        MhchemParser.upstreamCommit,
        'acaf5adb97a08deb234e0a8d62c807c17ee650d6',
      );
    });
  });

  group('typed conversion', () {
    test('supports every declared mode', () {
      expect(
        MhchemParser.convert('H2O', mode: MhchemMode.ce),
        r'{\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}',
      );
      expect(
        MhchemParser.convert('1 kg', mode: MhchemMode.pu),
        r'{1~\mathrm{kg}}',
      );
      expect(
        MhchemParser.convert(r'x = \ce{H2O}', mode: MhchemMode.tex),
        r'x = {\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}',
      );
    });

    test('returns empty output for empty input in every mode', () {
      for (final mode in MhchemMode.values) {
        expect(MhchemParser.convert('', mode: mode), isEmpty);
      }
    });
  });

  group('legacy compatibility wrapper', () {
    test('delegates valid string modes to the typed API', () {
      for (final mode in MhchemMode.values) {
        const input = 'H2O';
        expect(
          _legacyToTex(input, mode.name),
          MhchemParser.convert(input, mode: mode),
        );
      }
    });

    test('reports invalid modes as public argument errors', () {
      expect(
        () => _legacyToTex('H2O', 'invalid'),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.invalidValue, 'invalidValue', 'invalid')
              .having((error) => error.name, 'name', 'type')
              .having(
                (error) => error.message,
                'message',
                contains('tex, ce, pu'),
              ),
        ),
      );
    });
  });

  group('complete TeX expansion', () {
    const nested = r'\ce{$\frac{\ce{$\underset{x}{\ce{H2O}}$}}{1}$}';
    const expanded =
        r'{\frac{{\underset{x}{{\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}} }}{1} }';

    test('converges across multiple passes', () {
      expect(MhchemParser.expandAllTex(nested), expanded);
    });

    test('keeps primary conversion single-pass and upstream-exact', () {
      expect(
        MhchemParser.convert(nested, mode: MhchemMode.tex),
        r'{\frac{\ce{$\underset{x}{\ce{H2O}}$}}{1} }',
      );
    });

    test('throws a pass-limit error instead of returning partial output', () {
      expect(
        () => MhchemParser.expandAllTex(nested, maxPasses: 2),
        throwsA(
          isA<MhchemExpansionException>()
              .having(
                (error) => error.reason,
                'reason',
                MhchemExpansionFailure.passLimit,
              )
              .having(
                (error) => error.passesCompleted,
                'passesCompleted',
                2,
              )
              .having(
                (error) => error.lastOutput,
                'lastOutput',
                contains(r'\ce{H2O}'),
              ),
        ),
      );
    });

    test('throws a non-progress error instead of looping', () {
      expect(
        () => MhchemParser.expandAllTex(r'\ce{'),
        throwsA(
          isA<MhchemExpansionException>()
              .having(
                (error) => error.reason,
                'reason',
                MhchemExpansionFailure.noProgress,
              )
              .having(
                (error) => error.passesCompleted,
                'passesCompleted',
                1,
              )
              .having(
                (error) => error.lastOutput,
                'lastOutput',
                r'\ce{',
              ),
        ),
      );
    });

    test('requires a positive pass limit', () {
      expect(
        () => MhchemParser.expandAllTex('H2O', maxPasses: 0),
        throwsArgumentError,
      );
      expect(
        () => MhchemParser.expandAllTex('H2O', maxPasses: -1),
        throwsArgumentError,
      );
    });

    test('leaves text without executable commands unchanged', () {
      expect(MhchemParser.expandAllTex('plain TeX'), 'plain TeX');
      expect(
        MhchemParser.expandAllTex(r'\\ce{literal}'),
        r'\\ce{literal}',
      );
    });
  });
}
