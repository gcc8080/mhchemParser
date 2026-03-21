import 'package:test/test.dart';
import 'package:mhchem_parser/mhchem_parser.dart';

void main() {
  // tex
  test('tex: ce and pu in tex', () {
    expect(
      MhchemParser.toTex(r'm_{\ce{H2O}} = \pu{1.2kg}', 'tex'),
      equals(r'm_{{\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}} = {1.2~\mathrm{kg}}'),
    );
  });

  // Chemical Equations
  test('ce: CO2 + C -> 2 CO', () {
    expect(
      MhchemParser.toTex('CO2 + C -> 2 CO', 'ce'),
      equals(r'{\mathrm{CO}{\vphantom{A}}_{\smash[t]{2}} {}+{} \mathrm{C} {}\mathrel{\longrightarrow}{} 2\,\mathrm{CO}}'),
    );
  });

  test('ce: Hg^2+ ->[I-] HgI2 ->[I-] [Hg^{II}I4]^2-', () {
    expect(
      MhchemParser.toTex(r'Hg^2+ ->[I-] HgI2 ->[I-] [Hg^{II}I4]^2-', 'ce'),
      equals(r'{\mathrm{Hg}{\vphantom{A}}^{2+} {}\mathrel{\xrightarrow{\mathrm{I}{\vphantom{A}}^{-}}}{} \mathrm{HgI}{\vphantom{A}}_{\smash[t]{2}} {}\mathrel{\xrightarrow{\mathrm{I}{\vphantom{A}}^{-}}}{} [\mathrm{Hg}{\vphantom{A}}^{\mathrm{II}}\mathrm{I}{\vphantom{A}}_{\smash[t]{4}}]{\vphantom{A}}^{2-}}'),
    );
  });

  // Chemical formulae
  test('ce: H2O', () {
    expect(MhchemParser.toTex('H2O', 'ce'),
      equals(r'{\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: Sb2O3', () {
    expect(MhchemParser.toTex('Sb2O3', 'ce'),
      equals(r'{\mathrm{Sb}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}{\vphantom{A}}_{\smash[t]{3}}}'));
  });

  // Charges
  test('ce: H+', () {
    expect(MhchemParser.toTex('H+', 'ce'),
      equals(r'{\mathrm{H}{\vphantom{A}}^{+}}'));
  });

  test('ce: CrO4^2-', () {
    expect(MhchemParser.toTex('CrO4^2-', 'ce'),
      equals(r'{\mathrm{CrO}{\vphantom{A}}_{\smash[t]{4}}{\vphantom{A}}^{2-}}'));
  });

  test('ce: [AgCl2]-', () {
    expect(MhchemParser.toTex('[AgCl2]-', 'ce'),
      equals(r'{[\mathrm{AgCl}{\vphantom{A}}_{\smash[t]{2}}]{\vphantom{A}}^{-}}'));
  });

  test('ce: Y^99+', () {
    expect(MhchemParser.toTex('Y^99+', 'ce'),
      equals(r'{\mathrm{Y}{\vphantom{A}}^{99+}}'));
  });

  test('ce: Y^{99+}', () {
    expect(MhchemParser.toTex(r'Y^{99+}', 'ce'),
      equals(r'{\mathrm{Y}{\vphantom{A}}^{99+}}'));
  });

  // Stoichiometric Numbers
  test('ce: 2 H2O', () {
    expect(MhchemParser.toTex('2 H2O', 'ce'),
      equals(r'{2\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: 2H2O', () {
    expect(MhchemParser.toTex('2H2O', 'ce'),
      equals(r'{2\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: 0.5 H2O', () {
    expect(MhchemParser.toTex('0.5 H2O', 'ce'),
      equals(r'{0.5\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: 1/2 H2O', () {
    expect(MhchemParser.toTex('1/2 H2O', 'ce'),
      equals(r'{\mathchoice{\textstyle\frac{1}{2}}{\frac{1}{2}}{\frac{1}{2}}{\frac{1}{2}}\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: (1/2) H2O', () {
    expect(MhchemParser.toTex('(1/2) H2O', 'ce'),
      equals(r'{(1/2)\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test(r'ce: $n$ H2O', () {
    expect(MhchemParser.toTex(r'$n$ H2O', 'ce'),
      equals(r'{n \,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: n H2O', () {
    expect(MhchemParser.toTex('n H2O', 'ce'),
      equals(r'{n\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: nH2O', () {
    expect(MhchemParser.toTex('nH2O', 'ce'),
      equals(r'{n\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  test('ce: n/2 H2O', () {
    expect(MhchemParser.toTex('n/2 H2O', 'ce'),
      equals(r'{\mathchoice{\textstyle\frac{n}{2}}{\frac{n}{2}}{\frac{n}{2}}{\frac{n}{2}}\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  // Reaction Arrows
  test('ce: A -> B', () {
    expect(MhchemParser.toTex('A -> B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longrightarrow}{} \mathrm{B}}'));
  });

  test('ce: A <- B', () {
    expect(MhchemParser.toTex('A <- B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longleftarrow}{} \mathrm{B}}'));
  });

  test('ce: A <-> B', () {
    expect(MhchemParser.toTex('A <-> B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longleftrightarrow}{} \mathrm{B}}'));
  });

  test('ce: A <--> B', () {
    expect(MhchemParser.toTex('A <--> B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longleftrightarrows}{} \mathrm{B}}'));
  });

  test('ce: A <=> B', () {
    expect(MhchemParser.toTex('A <=> B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longrightleftharpoons}{} \mathrm{B}}'));
  });

  test('ce: A <=>> B', () {
    expect(MhchemParser.toTex('A <=>> B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longRightleftharpoons}{} \mathrm{B}}'));
  });

  test('ce: A <<=> B', () {
    expect(MhchemParser.toTex('A <<=> B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\longLeftrightharpoons}{} \mathrm{B}}'));
  });

  test('ce: A ->[H2O] B', () {
    expect(MhchemParser.toTex('A ->[H2O] B', 'ce'),
      equals(r'{\mathrm{A} {}\mathrel{\xrightarrow{\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}}{} \mathrm{B}}'));
  });

  // Parentheses, Brackets, Braces
  test('ce: (NH4)2S', () {
    expect(MhchemParser.toTex('(NH4)2S', 'ce'),
      equals(r'{(\mathrm{NH}{\vphantom{A}}_{\smash[t]{4}}){\vphantom{A}}_{\smash[t]{2}}\mathrm{S}}'));
  });

  // States of Aggregation
  test('ce: H2(aq)', () {
    expect(MhchemParser.toTex('H2(aq)', 'ce'),
      equals(r'{\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mskip2mu (\mathrm{aq})}'));
  });

  // Bonds
  test('ce: C6H5-CHO', () {
    expect(MhchemParser.toTex('C6H5-CHO', 'ce'),
      equals(r'{\mathrm{C}{\vphantom{A}}_{\smash[t]{6}}\mathrm{H}{\vphantom{A}}_{\smash[t]{5}}{-}\mathrm{CHO}}'));
  });

  test('ce: A-B=C#D', () {
    expect(MhchemParser.toTex('A-B=C#D', 'ce'),
      equals(r'{\mathrm{A}{-}\mathrm{B}{=}\mathrm{C}{\equiv}\mathrm{D}}'));
  });

  // Addition Compounds
  test('ce: KCr(SO4)2*12H2O', () {
    expect(MhchemParser.toTex('KCr(SO4)2*12H2O', 'ce'),
      equals(r'{\mathrm{KCr}(\mathrm{SO}{\vphantom{A}}_{\smash[t]{4}}){\vphantom{A}}_{\smash[t]{2}}\,{\cdot}\,12\,\mathrm{H}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}}'));
  });

  // Oxidation States
  test('ce: Fe^{II}Fe^{III}2O4', () {
    expect(MhchemParser.toTex(r'Fe^{II}Fe^{III}2O4', 'ce'),
      equals(r'{\mathrm{Fe}{\vphantom{A}}^{\mathrm{II}}\mathrm{Fe}{\vphantom{A}}^{\mathrm{III}}{\vphantom{A}}_{\smash[t]{2}}\mathrm{O}{\vphantom{A}}_{\smash[t]{4}}}'));
  });

  // Equation Operators
  test('ce: A + B', () {
    expect(MhchemParser.toTex('A + B', 'ce'),
      equals(r'{\mathrm{A} {}+{} \mathrm{B}}'));
  });

  // Precipitate and Gas
  test('ce: SO4^2- + Ba^2+ -> BaSO4 v', () {
    expect(MhchemParser.toTex('SO4^2- + Ba^2+ -> BaSO4 v', 'ce'),
      equals(r'{\mathrm{SO}{\vphantom{A}}_{\smash[t]{4}}{\vphantom{A}}^{2-} {}+{} \mathrm{Ba}{\vphantom{A}}^{2+} {}\mathrel{\longrightarrow}{} \mathrm{BaSO}{\vphantom{A}}_{\smash[t]{4}} \downarrow{} }'));
  });

  // \pu tests
  test('pu: 123 kJ', () {
    expect(MhchemParser.toTex('123 kJ', 'pu'),
      equals(r'{123~\mathrm{kJ}}'));
  });

  test('pu: 123 mm2', () {
    expect(MhchemParser.toTex('123 mm2', 'pu'),
      equals(r'{123~\mathrm{mm^{2}}}'));
  });

  test('pu: 123 J s', () {
    expect(MhchemParser.toTex('123 J s', 'pu'),
      equals(r'{123~\mathrm{J}\mkern3mu \mathrm{s}}'));
  });

  test('pu: 123 J*s', () {
    expect(MhchemParser.toTex('123 J*s', 'pu'),
      equals(r'{123~\mathrm{J}\mkern1mu{\cdot}\mkern1mu \mathrm{s}}'));
  });

  test('pu: 123 kJ/mol', () {
    expect(MhchemParser.toTex('123 kJ/mol', 'pu'),
      equals(r'{123~\mathrm{kJ}/\mathrm{mol}}'));
  });

  test('pu: 123 kJ//mol', () {
    expect(MhchemParser.toTex('123 kJ//mol', 'pu'),
      equals(r'{123~\mathchoice{\textstyle\frac{\mathrm{kJ}}{\mathrm{mol}}}{\frac{\mathrm{kJ}}{\mathrm{mol}}}{\frac{\mathrm{kJ}}{\mathrm{mol}}}{\frac{\mathrm{kJ}}{\mathrm{mol}}}}'));
  });

  test('pu: 123 kJ mol^-1', () {
    expect(MhchemParser.toTex('123 kJ mol^-1', 'pu'),
      equals(r'{123~\mathrm{kJ}\mkern3mu \mathrm{mol^{-1}}}'));
  });

  test('pu: 1.2e3 kJ', () {
    expect(MhchemParser.toTex('1.2e3 kJ', 'pu'),
      equals(r'{1.2\cdot 10^{3}~\mathrm{kJ}}'));
  });

  test('pu: 1234', () {
    expect(MhchemParser.toTex('1234', 'pu'),
      equals('{1234}'));
  });

  test('pu: 12345', () {
    expect(MhchemParser.toTex('12345', 'pu'),
      equals(r'{12\mkern2mu 345}'));
  });

  test('pu: 1\u00B0C', () {
    expect(MhchemParser.toTex('1\u00B0C', 'pu'),
      equals(r'{1~\mathrm{{}^{\circ}C}}'));
  });

  test('pu: .25', () {
    expect(MhchemParser.toTex('.25', 'pu'),
      equals('{.25}'));
  });
}
