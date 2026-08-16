## 1. Baseline and Package Metadata

- [x] 1.1 Add the repository-level Apache-2.0 license and `UPSTREAM.md` recording mhchemParser 4.2.2, commit `acaf5adb97a08deb234e0a8d62c807c17ee650d6`, vendored paths, and the audited source SHA-256.
- [x] 1.2 Add an automated source-integrity check that fails when the pinned reference file or expected hash changes unexpectedly.
- [x] 1.3 Update the Dart package to version `0.1.0` with SDK constraint `>=3.6.0 <4.0.0`, while keeping runtime dependencies empty.
- [x] 1.4 Expose immutable public package metadata for the Dart implementation version and upstream compatibility version, and add unit tests for both values.

## 2. Canonical Corpus and JavaScript Oracle

- [x] 2.1 Implement a deterministic tool that extracts stable case identifiers, modes, inputs, and expected outputs from the pinned upstream `test-dist.html` into a UTF-8 JSON corpus.
- [x] 2.2 Generate and commit the canonical corpus, then add integrity assertions for exactly 117 unique cases partitioned into 1 `tex`, 95 `ce`, and 21 `pu` cases.
- [x] 2.3 Add a non-mutating corpus check mode that fails when regeneration differs from the committed JSON fixture.
- [x] 2.4 Add a Node-based oracle runner that verifies every stored expectation against the pinned JavaScript 4.2.2 distribution and reports the case identifier, mode, and input on failure.

## 3. Public Dart API and Expansion Safety

- [x] 3.1 Add `MhchemMode` and `MhchemParser.convert(String input, {required MhchemMode mode})` as the typed, single-pass entry point that centralizes all supported-mode dispatch.
- [x] 3.2 Convert `MhchemParser.toTex(String input, String type)` into a deprecated delegating wrapper retained throughout `0.x`, and test valid-mode parity plus deterministic `ArgumentError` details for invalid modes.
- [x] 3.3 Add `MhchemParser.expandAllTex(String input, {int maxPasses = 16})` with caller validation, convergence detection, and public `MhchemExpansionException` pass-limit/non-progress reasons.
- [x] 3.4 Add focused tests proving recursive expansion converges for nested `\\ce`/`\\pu` content while the primary converter retains upstream single-pass output.

## 4. Dart 4.2.2 Conformance

- [x] 4.1 Replace duplicated hand-written canonical examples with a data-driven Dart test that reads the shared JSON corpus and produces case-specific diagnostics.
- [x] 4.2 Run all 117 cases through the Dart port and reconcile every mismatch against the pinned TypeScript source without changing upstream expected values.
- [x] 4.3 Add focused regression tests for empty input, Unicode dash/ellipsis normalization, complex nested TeX, isotopes, arrows, bonds, Kröger-Vink notation, uncertainty values, and invalid public mode input.
- [x] 4.4 Assert that renderer-extension commands and residual embedded mhchem commands remain unchanged in exact single-pass output.

## 5. Static Analysis and Continuous Integration

- [x] 5.1 Add Dart 3.6-compatible analysis configuration, format the package, and resolve all analyzer findings without altering the conformance contract.
- [x] 5.2 Add GitHub Actions jobs for the exact Dart 3.6 baseline and current stable Dart, running source hash, corpus regeneration, JavaScript oracle, formatting, analysis, and Dart tests.
- [x] 5.3 Add a Flutter 3.27.4 consumer fixture or CI smoke job proving the nested pure-Dart package resolves without Flutter plugins, WebView, or JavaScript runtime dependencies.
- [x] 5.4 Add a package dry-run check that validates publishable contents and confirms vendored test tooling is not introduced as a runtime dependency.

## 6. Documentation and Release Verification

- [x] 6.1 Update root and package English documentation with the Dart 3.6 baseline, independent versioning, fixed Git dependency path, typed API, legacy deprecation, recursive-expansion behavior, and exact-output boundary.
- [x] 6.2 Apply the same contract and migration guidance to the Chinese documentation and add a changelog entry for both breaking configuration changes.
- [x] 6.3 Run the complete minimum/stable verification suite, record all 117 JS and Dart cases passing, run `openspec validate align-mhchem-parser-4-2-2-conformance --strict`, and prepare release notes without creating a tag, GitHub release, or pub.dev publication.
