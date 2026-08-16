# mhchemParser Dart port

[中文](README_zh.md)

This repository contains the audited mhchemParser 4.2.2 JavaScript/TypeScript
baseline and an independently versioned, dependency-free Dart port that converts
mhchem input to LaTeX.

## Compatibility

| Component | Contract |
|---|---|
| Dart package | `mhchem_parser 0.1.0` |
| Upstream behavior | mhchemParser `4.2.2`, commit `acaf5adb97a08deb234e0a8d62c807c17ee650d6` |
| Dart SDK | `>=3.6.0 <4.0.0` |
| Downstream Flutter baseline | Flutter `3.27.4` or newer compatible releases |
| Runtime dependencies | None; pure Dart |

The Dart release version and upstream compatibility version are intentionally
separate. See [UPSTREAM.md](UPSTREAM.md) for immutable source hashes, provenance,
and verification commands.

## Repository layout

```text
mhchemParser/
├── js/mhchemParser/               # Audited upstream 4.2.2 source and JS oracle
├── flutter/mhchemParser/          # Publishable pure-Dart package
├── tools/conformance/             # Source, corpus, oracle, and runtime checks
├── tool/flutter_consumer/         # Flutter 3.27.4 resolution/smoke fixture
└── openspec/                      # Versioned behavior and implementation plan
```

## Installation

Pin a full commit or an approved immutable release tag. The Dart package remains
in the repository subdirectory:

```yaml
dependencies:
  mhchem_parser:
    git:
      url: https://github.com/gcc8080/mhchemParser.git
      ref: <approved-release-tag-or-full-commit-sha>
      path: flutter/mhchemParser
```

A local path dependency is also supported during development:

```yaml
dependencies:
  mhchem_parser:
    path: ../mhchemParser/flutter/mhchemParser
```

## Public API

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

final onePass = MhchemParser.convert(
  r'm_{\ce{H2O}} = \pu{1.2kg}',
  mode: MhchemMode.tex,
);

final completelyExpanded = MhchemParser.expandAllTex(
  r'\ce{$\frac{\ce{H2O}}{1}$}',
);
```

`convert` performs exactly one upstream-compatible pass. `expandAllTex` is
opt-in, defaults to 16 passes, and throws `MhchemExpansionException` with a
`passLimit` or `noProgress` reason rather than returning incomplete output.

The old `MhchemParser.toTex(input, 'ce')` entry point is deprecated but remains
available throughout the complete `0.x` release line. It will not be removed
before `1.0.0`.

Public metadata is available as:

- `MhchemParser.packageVersion`
- `MhchemParser.upstreamVersion`
- `MhchemParser.upstreamCommit`

## Exact-output boundary

The parser preserves upstream 4.2.2 LaTeX character-for-character for the 117
canonical cases. It does not rewrite output into a smaller KaTeX subset.
Commands such as `\mathchoice`, `\smash`, lapping, primitive vertical
shifts, `\tripledash`, and mhchem long arrows belong to the downstream
renderer contract.

The JavaScript implementation is used only as an offline conformance oracle.
The shipped Dart package has no JavaScript, Flutter, WebView, plugin, or network
runtime dependency.

## Verification

```sh
node tools/conformance/check-upstream.mjs
node tools/conformance/extract-corpus.mjs --check
node tools/conformance/verify-oracle.mjs
node tools/conformance/check-runtime-boundary.mjs

cd flutter/mhchemParser
dart pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

CI runs the checks with Dart 3.6, current stable Dart, and a Flutter 3.27.4
consumer. The 117 examples are the pinned canonical compatibility corpus, not a
claim that every malformed input behaves identically.

## Release boundary

This change prepares package version `0.1.0`. Creating a Git tag, GitHub
release, or pub.dev publication requires separate authorization.

## License

Apache License 2.0. The upstream copyright and attribution are preserved in
[LICENSE](LICENSE), [UPSTREAM.md](UPSTREAM.md), and the audited source files.
