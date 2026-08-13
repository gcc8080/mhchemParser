## Purpose

Defines a reproducible pure-Dart conversion contract for mhchemParser 4.2.2 so downstream renderers can distinguish parser regressions from unsupported LaTeX rendering behavior.

## ADDED Requirements

### Requirement: Immutable upstream compatibility baseline
The package SHALL declare upstream mhchemParser 4.2.2 at commit `acaf5adb97a08deb234e0a8d62c807c17ee650d6` as its behavioral reference. The vendored reference source SHALL retain its Apache-2.0 license, its provenance SHALL be documented at repository level, and its audited SHA-256 value `193b84cc5a18d44df2d4ebb2281b94cf183a316193ba4d1407d1b6dba15c5502` SHALL be verifiable.

#### Scenario: Baseline metadata is inspectable
- **WHEN** a consumer or maintainer inspects the package metadata and provenance documentation
- **THEN** the Dart package release version and the upstream compatibility version `4.2.2` are identified separately
- **AND** the immutable upstream commit and license are present

#### Scenario: Vendored reference source drifts
- **WHEN** the vendored upstream source no longer matches the recorded SHA-256 value
- **THEN** conformance verification fails before Dart output is accepted as baseline-compatible

### Requirement: Exact canonical conversion
For every valid canonical example published with the pinned upstream baseline, the Dart converter SHALL return LaTeX identical to the upstream JavaScript converter for the same input and mode. Equality SHALL include grouping, spacing, command spelling, and command retention; the package MUST NOT normalize output into a smaller KaTeX command subset.

#### Scenario: Chemical expression conversion
- **WHEN** any of the 95 canonical `ce` inputs is converted in chemical-expression mode
- **THEN** the result is character-for-character identical to the pinned JavaScript 4.2.2 result

#### Scenario: Physical-unit conversion
- **WHEN** any of the 21 canonical `pu` inputs is converted in physical-unit mode
- **THEN** the result is character-for-character identical to the pinned JavaScript 4.2.2 result

#### Scenario: TeX pass-through conversion
- **WHEN** the canonical `tex` input containing embedded `\\ce{...}` and `\\pu{...}` commands is converted in TeX mode
- **THEN** the result is character-for-character identical to the pinned JavaScript 4.2.2 result

#### Scenario: Output requires downstream renderer extensions
- **WHEN** a valid input produces commands such as `\\mathchoice`, `\\smash`, `\\llap`, `\\rlap`, `\\lower`, `\\raise`, `\\tripledash`, or mhchem-specific long arrows
- **THEN** those commands are preserved exactly rather than rewritten or rejected by the parser package

### Requirement: Supported conversion modes and compatibility entry point
The package SHALL provide a type-safe public representation of the `tex`, `ce`, and `pu` modes. It SHALL also retain the existing string-mode conversion entry point as a deprecated compatibility wrapper for valid callers, and invalid string modes SHALL fail with a public argument error rather than an internal null assertion or state-machine failure.

#### Scenario: Type-safe conversion
- **WHEN** a caller converts an input using any type-safe supported mode
- **THEN** the output is identical to conversion of the same input through the corresponding upstream mode

#### Scenario: Existing valid string-mode caller
- **WHEN** an existing caller uses the deprecated string entry point with `tex`, `ce`, or `pu`
- **THEN** conversion succeeds with the same output as the type-safe entry point

#### Scenario: Invalid string mode
- **WHEN** a caller supplies a string other than `tex`, `ce`, or `pu`
- **THEN** conversion fails deterministically with an argument error that identifies the invalid value and supported values

### Requirement: Bounded recursive embedded-command expansion
The package SHALL provide an opt-in TeX expansion operation that repeatedly expands embedded `\\ce{...}` and `\\pu{...}` commands using the same 4.2.2 conversion rules. The operation SHALL default to a maximum of 16 passes, SHALL accept an explicit positive pass limit, and MUST fail clearly instead of silently returning partial output when recognized commands remain after reaching the limit or a non-progressing state. The primary conversion operation SHALL remain single-pass and upstream-exact.

#### Scenario: Nested embedded commands converge
- **WHEN** a TeX expression contains nested supported mhchem commands that require more than one conversion pass
- **THEN** the opt-in expansion operation returns an expression with all recognized embedded mhchem commands expanded

#### Scenario: Expansion reaches its pass limit
- **WHEN** recognized embedded mhchem commands remain after the configured maximum number of passes
- **THEN** the operation fails with a depth-limit error and does not report partial output as complete

#### Scenario: Expansion makes no progress
- **WHEN** a pass leaves the expression unchanged while recognized embedded mhchem commands remain
- **THEN** the operation fails with a non-progress error instead of looping

#### Scenario: Primary conversion receives nested content
- **WHEN** the primary single-pass converter is used on an input whose upstream result retains an embedded mhchem command
- **THEN** it returns the exact upstream single-pass result without implicitly invoking recursive expansion

### Requirement: Dart and Flutter consumer baseline
The package SHALL support Dart SDK versions from 3.6.0 inclusive to 4.0.0 exclusive and SHALL remain a pure-Dart runtime package with no Flutter SDK or JavaScript runtime dependency. Its supported range SHALL be verified on Dart 3.6 and on the current stable Dart SDK so that it can be consumed by Flutter 3.27.4 and newer compatible Flutter releases.

#### Scenario: Minimum supported SDK
- **WHEN** dependencies are resolved and the package is analyzed and tested with Dart 3.6
- **THEN** all supported package checks succeed

#### Scenario: Flutter renderer consumes the package
- **WHEN** a Flutter 3.27.4 application adds the package from its repository subdirectory at a fixed tag or commit
- **THEN** dependency resolution succeeds without adding a Flutter plugin, WebView, or JavaScript runtime dependency

#### Scenario: Current stable SDK
- **WHEN** the package is analyzed and tested with the current stable Dart SDK below 4.0.0
- **THEN** all supported package checks succeed

### Requirement: Reproducible conformance verification
The repository SHALL contain a machine-readable corpus of exactly 117 canonical cases, partitioned as 1 `tex`, 95 `ce`, and 21 `pu` cases, whose provenance is the pinned upstream test suite. Automated verification SHALL check corpus identity and counts, compare the pinned JavaScript converter with the stored expectations, compare the Dart converter with the same expectations, and run formatting and static analysis checks in continuous integration.

#### Scenario: Complete unchanged corpus
- **WHEN** the conformance verification runs against the pinned source and an unmodified canonical corpus
- **THEN** it verifies exactly 117 cases with the expected per-mode counts through both JavaScript and Dart converters

#### Scenario: Corpus case is missing or duplicated
- **WHEN** a canonical case is removed, duplicated, or assigned to the wrong mode
- **THEN** the corpus identity or count check fails

#### Scenario: JavaScript expectation drifts
- **WHEN** a stored expected value differs from the pinned JavaScript converter result
- **THEN** the JavaScript oracle check fails and identifies the affected case

#### Scenario: Dart behavior drifts
- **WHEN** the Dart converter result differs from the stored expected value
- **THEN** the Dart conformance check fails and identifies the mode, input, expected output, and actual output

### Requirement: Independent Dart release identity
The Dart port SHALL use its own semantic package version beginning at `0.1.0` and SHALL expose upstream compatibility version `4.2.2` independently in public package metadata. Documentation SHALL avoid implying that the Dart package release number alone proves upstream conformance.

#### Scenario: Consumer inspects version identity
- **WHEN** a consumer reads package metadata or the public compatibility metadata
- **THEN** the Dart implementation version and its pinned mhchemParser compatibility version are unambiguous
