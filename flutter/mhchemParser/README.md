# mhchem_parser

[中文](README_zh.md)

A dependency-free, pure-Dart port conforming to the 117 canonical
mhchemParser 4.2.2 examples.

## Compatibility

- Dart package version: `0.1.0`
- Upstream compatibility: `4.2.2`
- Upstream commit: `acaf5adb97a08deb234e0a8d62c807c17ee650d6`
- Dart SDK: `>=3.6.0 <4.0.0`
- Verified downstream baseline: Flutter `3.27.4`
- Runtime dependencies: none

The package version describes this Dart implementation. It does not replace the
separate upstream compatibility version.

## Installation

Pin an immutable repository tag or full commit:

```yaml
dependencies:
  mhchem_parser:
    git:
      url: https://github.com/gcc8080/mhchemParser.git
      ref: <approved-release-tag-or-full-commit-sha>
      path: flutter/mhchemParser
```

## Usage

```dart
import 'package:mhchem_parser/mhchem_parser.dart';

final equation = MhchemParser.convert(
  'CO2 + C -> 2 CO',
  mode: MhchemMode.ce,
);
final unit = MhchemParser.convert(
  '123 kJ*mol-1',
  mode: MhchemMode.pu,
);
final onePassTex = MhchemParser.convert(
  r'm_{\ce{H2O}}',
  mode: MhchemMode.tex,
);
final expandedTex = MhchemParser.expandAllTex(
  r'\ce{$\underset{x}{\ce{H2O}}$}',
);
```

### Modes

| Value | Input |
|---|---|
| `MhchemMode.ce` | Chemical equations and formulae |
| `MhchemMode.pu` | Physical units |
| `MhchemMode.tex` | TeX containing embedded `\ce` and `\pu` |

`convert` is always single-pass and preserves exact upstream output.
`expandAllTex` defaults to 16 passes and throws `MhchemExpansionException`
with `MhchemExpansionFailure.passLimit` or `.noProgress` when complete
expansion cannot be proven.

`MhchemParser.toTex(String input, String type)` is deprecated, delegates to
the typed API, and remains available throughout `0.x`. It will not be removed
before `1.0.0`.

## Output contract

Canonical output is character-for-character compatible with the pinned
JavaScript oracle. Renderer-extension commands are preserved instead of
normalized. Rendering support remains a downstream responsibility.

The JavaScript baseline and Node verification tools are repository-only test
assets. They are not runtime dependencies and are not imported by this package.

## Testing

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

Repository-level provenance and conformance commands are documented in
[`UPSTREAM.md`](../../UPSTREAM.md).

## Release status

Version `0.1.0` is prepared by the conformance change. No tag, GitHub release,
or pub.dev publication is implied.

## License

Apache License 2.0. See [LICENSE](LICENSE) and the repository provenance record.
