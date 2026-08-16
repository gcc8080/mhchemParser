## Context

See `proposal.md` for motivation. The repository contains the original JavaScript/TypeScript mhchemParser 4.2.2 distribution beside a hand-ported pure-Dart package under `flutter/mhchemParser`. The reference TypeScript source matches upstream commit `acaf5adb97a08deb234e0a8d62c807c17ee650d6`, but the Dart package currently declares `>=2.17.0 <3.0.0`, exposes modes as unchecked strings, and copies only 47 of the 117 upstream test examples into Dart tests.

The downstream `flutter_math_plus` renderer will consume the Dart output as a separate contract from KaTeX Core 0.18.4. Some correct mhchemParser 4.2.2 results intentionally contain commands that bare KaTeX does not define or that the current Flutter renderer does not support. Those renderer gaps must remain visible rather than being hidden by parser-side rewrites.

## Goals / Non-Goals

**Goals:**

- Make the 4.2.2 compatibility claim reproducible from immutable source provenance through automated JS and Dart checks.
- Give downstream Dart 3.6 / Flutter 3.27.4 consumers a safe typed API while providing a migration path for current string-mode callers.
- Keep recursive expansion explicit and terminating so the primary API remains a faithful one-pass port.
- Keep runtime delivery pure Dart and dependency-free.

**Non-Goals:**

- Implement or validate visual rendering of the emitted LaTeX.
- Translate 4.2.2 output into KaTeX Core commands or add renderer-specific aliases.
- Claim equivalence for malformed inputs beyond explicitly tested error behavior, or for upstream versions newer than 4.2.2.
- Move the Dart package to the repository root, publish it to pub.dev, or change the repository's branching/release policy in this change.
- Replace the vendored JavaScript reference with a runtime JavaScript dependency.

## Decisions

### Pin source identity as well as the semantic version

The compatibility record will include the upstream version, full commit, Apache-2.0 attribution, and audited source SHA-256. A repository-level `UPSTREAM.md` will explain which files are vendored and how to verify them, and the root will carry the applicable license text.

Using only the string `4.2.2` was rejected because a vendored file can drift without its banner or package metadata changing. Following upstream `main` was rejected because it makes the output contract non-repeatable.

### Use one canonical JSON corpus for both implementations

A deterministic tool will extract the 117 `test(mode, input, expected)` entries from the pinned upstream test file into a UTF-8 JSON fixture with stable ordering and explicit case identifiers. A check mode will regenerate the representation in memory and fail on any difference instead of silently rewriting the committed fixture.

The Dart conformance test will load that fixture and call the Dart API. A Node-based oracle check will load the pinned JavaScript distribution and compare its results with the same fixture. CI will also assert the total and per-mode counts. Node is repository test tooling only; it is not a Dart runtime dependency.

Hand-maintained duplicate Dart test literals were rejected because they allowed the current 47/117 coverage gap and make escaping mistakes difficult to distinguish from parser defects. Calling JavaScript directly from Dart unit tests was rejected because it would make ordinary package tests depend on Node.

### Preserve exact output and fix the port, not the fixture

The stored expected output will remain the pinned upstream value, including whitespace, braces, residual embedded mhchem commands, and renderer-extension commands. When a Dart comparison fails, implementation behavior must be reconciled against the pinned TypeScript source; expected values cannot be edited merely to make the Dart test pass.

Normalizing output for KaTeX was rejected because that would create a third dialect, destroy differential-test value, and couple the parser to `flutter_math_plus`. Renderer support for `\\mathchoice`, `\\smash`, lapping, custom arrows, and related constructs belongs to the separate `support-mhchem-4-2-2-output-contract` change.

### Add a typed API without removing the legacy entry point during 0.x

The public library will add `MhchemMode` with `tex`, `ce`, and `pu` values and `MhchemParser.convert(String input, {required MhchemMode mode})` as the typed single-pass method. The existing `MhchemParser.toTex(String input, String type)` signature will validate its string, delegate to `convert`, and be marked deprecated. The wrapper remains available throughout `0.x` and can be removed only in `1.0.0` or later. Invalid strings throw `ArgumentError.value` with the allowed modes.

Changing the existing method's second parameter directly to an enum was rejected because it would force all consumers to migrate at once even though a delegating wrapper is inexpensive. Retaining unchecked strings as the only API was rejected because invalid values currently fail through an internal null assertion.

### Keep one-pass conversion upstream-exact and make recursion opt-in

The typed primary conversion method will perform exactly one upstream-equivalent pass. `MhchemParser.expandAllTex(String input, {int maxPasses = 16})` will repeatedly run TeX-mode conversion and accept only a caller-supplied positive limit. It will stop successfully when no recognized embedded `\\ce{` or `\\pu{` command remains. It throws `MhchemExpansionException` with a public reason value distinguishing `passLimit` from `noProgress`; the exception includes the configured limit and last complete intermediate value for diagnostics, but callers cannot mistake that value for a successful result.

Implicitly recursing in the main conversion method was rejected because several canonical upstream results intentionally retain embedded commands and would no longer compare exactly. An unbounded loop was rejected because malformed or deliberately self-reproducing content could otherwise consume unbounded CPU.

### Give the Dart port an independent release version

The Dart package will begin its own release line at `0.1.0`, while a public constant and package documentation will report upstream compatibility as `4.2.2`. The repository has no released Dart tags to migrate, and a pre-1.0 version accurately represents the port's current maturity.

Keeping the Dart package version at `4.2.2` was rejected because it conflates implementation maturity with compatibility and makes independent fixes impossible to version clearly. Encoding upstream compatibility only in build metadata was rejected because dependency resolution ignores build metadata for precedence.

### Verify the minimum and moving stable boundary

The package SDK constraint will become `>=3.6.0 <4.0.0`. CI will run fixture integrity, formatting, analysis, and Dart tests on the exact minimum SDK and the current stable SDK. A small downstream-resolution check will verify that Flutter 3.27.4 can consume the nested package without any Flutter SDK or plugin dependency.

Supporting Dart 2.x was rejected because it conflicts with the selected downstream baseline and would multiply language/API compatibility testing without improving the parser contract. Adding Flutter to the package environment was rejected because the implementation is pure Dart.

## Risks / Trade-offs

- **[The 117 examples are representative, not exhaustive]** → Describe the compatibility claim as canonical-corpus conformance, keep differential regression tests for every newly reported case, and avoid claiming all malformed-input behavior is identical.
- **[Fixture extraction can misread JavaScript escaping]** → Compare regenerated fixture values against the executable pinned JavaScript oracle and assert stable case identifiers and counts.
- **[Vendored source and fixture could be changed together]** → Verify the immutable source hash before accepting oracle results and review provenance changes separately.
- **[A new typed API plus a legacy wrapper expands surface area throughout 0.x]** → Centralize all conversion in `convert`, keep the wrapper trivial, and permit removal only at `1.0.0` or later.
- **[Recursive expansion can reject intentional literal `\\ce` text]** → Keep it opt-in, document that it is for executable mhchem commands, and leave single-pass conversion available for exact control.
- **[A moving stable CI job can expose unrelated SDK changes]** → Keep Dart 3.6 as the contractual gate and treat stable failures as compatibility work without weakening the pinned output corpus.
- **[Resetting the package version can break version-constrained path/git consumers]** → Document the change prominently; current callers can update their constraint while keeping the deprecated API wrapper.

## Migration Plan

1. Add provenance/license records and the independent package/upstream version metadata without changing conversion output.
2. Add the generated canonical fixture, its deterministic integrity check, and the JavaScript oracle; confirm the pinned reference passes all 117 cases.
3. Raise the SDK constraint, add analysis configuration, and introduce the typed API plus legacy wrapper and bounded expansion helper.
4. Run the Dart port against all 117 cases, reconcile every mismatch with the pinned source, and add focused regression tests for error and expansion behavior.
5. Add the minimum/current-stable CI matrix and downstream Flutter resolution check, then update both English and Chinese documentation.
6. After strict OpenSpec validation and all CI gates pass, prepare release notes but do not create a Git tag, GitHub release, or pub.dev publication until separately authorized.

Rollback is a normal Git revert before the first independent release. After release, retain the last passing tag and revert the dependency pin in downstream consumers; no data migration is involved.
