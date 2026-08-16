# Upstream provenance

This repository contains an audited copy of mhchemParser and a separately
versioned pure-Dart port.

## Compatibility baseline

| Field | Value |
|---|---|
| Upstream project | [mhchem/mhchemParser](https://github.com/mhchem/mhchemParser) |
| Upstream version | `4.2.2` |
| Upstream commit | `acaf5adb97a08deb234e0a8d62c807c17ee650d6` |
| Upstream license | Apache-2.0, Martin Hensel (2015–2023) |
| Dart package path | `flutter/mhchemParser` |
| Dart package version | `0.1.0` |

The upstream JavaScript/TypeScript files remain test tooling and provenance
material. They are not imported by the Dart package at runtime.

## Audited files

| Repository path | SHA-256 |
|---|---|
| `js/mhchemParser/LICENSE.txt` | `e1be8c4e92fe92593d010397067705f351324c4478a7fa4d598e7a4734946728` |
| `js/mhchemParser/package.json` | `4628eca7a4f3f5d21ad4e5307e6481ef45df4f18c10018fd0839ec3b441329ef` |
| `js/mhchemParser/src/mhchemParser.ts` | `193b84cc5a18d44df2d4ebb2281b94cf183a316193ba4d1407d1b6dba15c5502` |
| `js/mhchemParser/dist/mhchemParser.js` | `95f75dfe279f408de267d8af81573aed41fe52db650a96a56230f3d0c01184f4` |
| `js/mhchemParser/test/test-dist.html` | `3dab404cfa1eee1779bb3ba3fb88817da134607bc02312a5d58a0185d77452bd` |

Verify the immutable baseline from the repository root:

```sh
node tools/conformance/check-upstream.mjs
node tools/conformance/extract-corpus.mjs --check
node tools/conformance/verify-oracle.mjs
```

Changing an audited file requires an intentional compatibility-baseline change,
new recorded hashes, regenerated conformance data, and separate review. Expected
outputs must not be edited merely to make the Dart port pass.

## Local work

The implementation under `flutter/mhchemParser` is a hand port whose release
version is independent of the upstream compatibility version. Local changes add
Dart APIs, safety checks, tests, documentation, and CI; they do not change the
audited upstream files.
