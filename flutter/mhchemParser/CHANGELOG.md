# Changelog

## 0.1.0

- **Breaking:** require Dart `>=3.6.0 <4.0.0`.
- **Breaking:** independently version the Dart port as `0.1.0` while declaring
  upstream mhchemParser compatibility as `4.2.2`.
- Add the typed `MhchemMode` and `MhchemParser.convert` API.
- Deprecate the string-mode `toTex` wrapper while retaining it throughout
  `0.x`.
- Add bounded recursive TeX expansion with public termination diagnostics.
- Verify all 117 canonical cases against the pinned JavaScript oracle.
