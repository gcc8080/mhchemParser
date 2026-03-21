# mhchem Parser

[中文](README_zh.md)

mhchem is an input syntax for typesetting chemical equations and physical units.

This project is a Dart/Flutter port of [mhchemParser](https://github.com/mhchem/mhchemParser) v4.2.2, converting mhchem syntax to LaTeX syntax for downstream integration with MathJax, KaTeX and similar projects.

## Project Structure

```
mhchemParser/
├── js/                         # Original JavaScript/TypeScript version (v4.2.2)
│   └── mhchemParser/
│       ├── src/                # TypeScript source
│       ├── dist/               # Compiled JS (UMD)
│       ├── esm/                # ES Module build
│       └── test/               # Test files
├── flutter/                    # Dart port
│   └── mhchemParser/
│       ├── lib/
│       │   ├── mhchem_parser.dart           # Public export
│       │   └── src/
│       │       ├── mhchem_parser.dart       # Public API
│       │       ├── mhchem_parser_core.dart  # Core parser (state machines)
│       │       ├── mhchem_texify.dart       # LaTeX renderer
│       │       └── types.dart               # Type definitions
│       ├── test/
│       │   └── mhchem_parser_test.dart      # Test cases
│       └── pubspec.yaml
└── README.md
```

## Dart Version

### Requirements

- Dart SDK: `>=2.17.0 <3.0.0`
- Flutter: `3.10.6` compatible
- Zero third-party dependencies

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mhchem_parser:
    path: path/to/flutter/mhchemParser
```

### Usage

```dart
import 'package:mhchem_parser/mhchem_parser.dart';

// Chemical equations
String tex = MhchemParser.toTex('CO2 + C -> 2 CO', 'ce');

// Physical units
String pu = MhchemParser.toTex('123 kJ*mol-1', 'pu');

// TeX strings (auto-replaces \ce and \pu)
String tex2 = MhchemParser.toTex(r'm_{\ce{H2O}}', 'tex');
```

### Supported Modes

| Mode   | Description        | Example Input         |
|--------|--------------------|-----------------------|
| `ce`   | Chemical equations | `CO2 + C -> 2 CO`    |
| `pu`   | Physical units     | `123 kJ*mol-1`       |
| `tex`  | TeX pass-through   | `m_{\ce{H2O}}`       |

### Features

- Chemical equations and formulae (elements, charges, stoichiometric numbers)
- Reaction arrows (`->`, `<->`, `<=>`, `<-->`, etc.)
- Chemical bonds (single, double, triple, aromatic, etc.)
- Isotopes and nuclide notation
- Oxidation states (Roman numerals)
- States of aggregation (`(aq)`, `(s)`, `(g)`, `(l)`)
- Physical units (SI units, scientific notation, thousand separators)
- Kröger-Vink notation
- Greek letters
- Color markup

### Running Tests

```bash
cd flutter/mhchemParser
dart pub get
dart test
```

## Original Version

For the original JavaScript/TypeScript version, see the [mhchemParser repository](https://github.com/mhchem/mhchemParser).

## License

The original project is licensed under [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0), copyright Martin Hensel (2015-2023).

The Dart port follows the same license.
