import 'package:mhchem_parser/mhchem_parser.dart';
import 'package:test/test.dart';

void main() {
  group('normalization parity', () {
    for (final dash in ['−', '–', '—', '‐']) {
      test('normalizes Unicode dash $dash', () {
        expect(
          MhchemParser.convert('A${dash}B', mode: MhchemMode.ce),
          r'{\mathrm{A}{-}\mathrm{B}}',
        );
      });
    }

    test('normalizes Unicode ellipsis', () {
      expect(
        MhchemParser.convert('A…B', mode: MhchemMode.ce),
        r'{\mathrm{A}{{\cdot}{\cdot}{\cdot}}\mathrm{B}}',
      );
    });
  });

  group('representative chemistry regressions', () {
    test('isotope output retains lapping commands', () {
      final output = MhchemParser.convert(
        r'^{227}_{90}Th+',
        mode: MhchemMode.ce,
      );
      expect(output, contains(r'\llap{227}'));
      expect(output, contains(r'\llap{\smash[t]{90}}'));
    });

    test('reaction arrows retain mhchem long-arrow commands', () {
      expect(
        MhchemParser.convert('A <=> B', mode: MhchemMode.ce),
        contains(r'\longrightleftharpoons'),
      );
      expect(
        MhchemParser.convert('A <=>> B', mode: MhchemMode.ce),
        contains(r'\longRightleftharpoons'),
      );
      expect(
        MhchemParser.convert('A <<=> B', mode: MhchemMode.ce),
        contains(r'\longLeftrightharpoons'),
      );
    });

    test('bond output retains renderer-extension commands', () {
      final output = MhchemParser.convert(
        r'A\bond{~-}B\bond{-~-}C',
        mode: MhchemMode.ce,
      );
      expect(output, contains(r'\rlap'));
      expect(output, contains(r'\lower'));
      expect(output, contains(r'\raise'));
      expect(output, contains(r'\tripledash'));
    });

    test('Kröger-Vink output retains multiplication and prime commands', () {
      final output = MhchemParser.convert(
        r"Li^x_{Li,1-2x}Mg^._{Li,x}$V$'_{Li,x}Cl^x_{Cl}",
        mode: MhchemMode.ce,
      );
      expect(output, contains(r'{\times}'));
      expect(output, contains(r'\prime'));
    });

    test('uncertainty values remain exact', () {
      expect(
        MhchemParser.convert('23.4782(32) m', mode: MhchemMode.pu),
        r'{23.4782(32)~\mathrm{m}}',
      );
    });

    test('complex TeX remains single-pass with residual commands', () {
      final output = MhchemParser.convert(
        r'A $\underset{x}{\ce{H2O}}$ B',
        mode: MhchemMode.ce,
      );
      expect(
        output,
        r'{\mathrm{A}~\underset{x}{\ce{H2O}} ~\mathrm{B}}',
      );
    });

    test('fractions retain style and smash commands', () {
      final output = MhchemParser.convert('1/2 H2O', mode: MhchemMode.ce);
      expect(output, contains(r'\mathchoice'));
      expect(output, contains(r'\smash[t]'));
    });
  });
}
