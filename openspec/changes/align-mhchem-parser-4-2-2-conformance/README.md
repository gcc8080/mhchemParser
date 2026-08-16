# align-mhchem-parser-4-2-2-conformance

Align the Dart port with the upstream mhchemParser 4.2.2 conformance contract and make it consumable by the Dart 3.6 / Flutter 3.27.4 baseline.

## Implementation verification

Verified on 2026-08-15 (America/Los_Angeles) at implementation commit
[`70598cd`](https://github.com/gcc8080/mhchemParser/commit/70598cd81ab323a38aa63f28c02b5dfd31c410ab)
in [GitHub Actions run 31918684859](https://github.com/gcc8080/mhchemParser/actions/runs/31918684859):

- The pinned source-integrity check, deterministic corpus regeneration, and
  JavaScript 4.2.2 oracle passed all 117 canonical cases: 1 `tex`, 95 `ce`,
  and 21 `pu`.
- Dart 3.6.0 and current stable Dart passed formatting, fatal-info analysis,
  every Dart test including the same 117 exact-output cases, and
  `dart pub publish --dry-run`.
- The Flutter 3.27.4 consumer passed resolution and tests without a Flutter
  plugin, WebView, JavaScript runtime, or runtime package dependency.
- `openspec validate align-mhchem-parser-4-2-2-conformance --strict` passed.

Release notes are prepared in `flutter/mhchemParser/CHANGELOG.md`. This change
does not create a Git tag, GitHub release, or pub.dev publication.
