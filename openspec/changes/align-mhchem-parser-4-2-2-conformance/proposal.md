## Why

The Dart port currently embeds the upstream mhchemParser 4.2.2 source but verifies only 47 of its 117 canonical examples and declares a pre-Dart-3 SDK range, so it cannot yet serve as a trustworthy input layer for `flutter_math_plus`. Establishing an explicit, reproducible conformance contract now prevents parser drift from being mistaken for renderer defects later.

## What Changes

- Lock the Dart port's behavioral reference to upstream mhchemParser 4.2.2 at the audited source commit and record its provenance and license at the repository level.
- Import all 117 upstream canonical examples into a machine-readable Dart conformance corpus and verify exact LaTeX output for the `tex`, `ce`, and `pu` modes.
- Add a repeatable JS-to-Dart differential check so fixture drift and future parser changes are detected automatically.
- **BREAKING**: raise the Dart SDK floor to `>=3.6.0 <4.0.0`, matching the Flutter 3.27.4 baseline selected for the downstream renderer.
- **BREAKING**: separate the Dart package release version from the upstream compatibility version, start the Dart port's own pre-1.0 release line, and expose the upstream version as package metadata.
- Add `MhchemParser.convert(String input, {required MhchemMode mode})` as the type-safe mode API with deterministic invalid-mode errors, while retaining the current string-based `toTex` entry point as a deprecated compatibility wrapper throughout the `0.x` release line.
- Add `MhchemParser.expandAllTex(String input, {int maxPasses = 16})` as an opt-in, depth-bounded helper for recursively expanding embedded `\\ce{...}` and `\\pu{...}` commands without changing the exact upstream behavior of the primary conversion API.
- Add static analysis, formatting, tests, and a Dart 3.6/current-stable CI matrix; update English and Chinese documentation accordingly.
- Preserve upstream 4.2.2 LaTeX output verbatim, including commands that require support from the downstream renderer; this change does not rewrite output into a reduced KaTeX subset.

## Capabilities

### New Capabilities

- `mhchem-parser-conformance`: Defines the versioned mhchemParser 4.2.2 conversion contract, supported modes, recursive-expansion boundary, provenance, and verification requirements for the pure-Dart package.

### Modified Capabilities

None. This repository has no existing OpenSpec capabilities.

## Impact

- Affected package: `flutter/mhchemParser` public API, SDK constraint, package metadata, tests, analysis configuration, and documentation.
- Affected repository tooling: conformance fixtures/extraction tooling, repository-level upstream notices/license, and GitHub Actions CI.
- Downstream consumers must use Dart 3.6 or newer. Existing callers may continue using `MhchemParser.toTex(String, String)` during a documented deprecation window.
- The current repository layout and Git dependency subdirectory remain unchanged; `flutter_math_plus` will continue to depend on `flutter/mhchemParser` at a fixed tag or commit.
- Applying this change prepares package version `0.1.0` but does not create a Git tag, GitHub release, or pub.dev publication; each release action requires separate authorization.
