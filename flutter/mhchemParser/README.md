# mhchem_parser

[中文](README_zh.md)

A Dart port of [mhchemParser](https://github.com/mhchem/mhchemParser) v4.2.2 — a parser that converts mhchem syntax to LaTeX syntax for chemical equations and physical units.

## Features

- **Chemical equations** (`\ce`): elements, charges, stoichiometric numbers, isotopes, reaction arrows, bonds, oxidation states, Kröger-Vink notation, etc.
- **Physical units** (`\pu`): SI units, scientific notation, thousand separators, temperature units, etc.
- **TeX pass-through** (`tex`): automatically replaces `\ce{...}` and `\pu{...}` within TeX strings.
- Zero third-party dependencies, pure Dart implementation.

## Requirements

- Dart SDK: `>=2.17.0 <3.0.0`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mhchem_parser:
    path: path/to/this/directory
```

## Usage

```dart
import 'package:mhchem_parser/mhchem_parser.dart';

// Chemical equations
MhchemParser.toTex('CO2 + C -> 2 CO', 'ce');
// → {\mathrm{CO}{\vphantom{A}}_{\smash[t]{2}} {}+{} \mathrm{C} {}\mathrel{\longrightarrow}{} 2\,\mathrm{CO}}

// Physical units
MhchemParser.toTex('123 kJ*mol-1', 'pu');
// → {123~\mathrm{kJ}\mkern1mu{\cdot}\mkern1mu \mathrm{mol^{-1}}}

// TeX with embedded \ce / \pu
MhchemParser.toTex(r'm_{\ce{H2O}}', 'tex');
```

## API

### `MhchemParser.toTex(String input, String type) → String`

| Parameter | Description |
|-----------|-------------|
| `input`   | The mhchem syntax string to parse |
| `type`    | One of `'ce'` (chemical equation), `'pu'` (physical unit), or `'tex'` (TeX pass-through) |

Returns a LaTeX string.

## Testing

```bash
dart pub get
dart test
```

## License

Based on [mhchemParser](https://github.com/mhchem/mhchemParser) by Martin Hensel, licensed under [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
