import 'mhchem_parser_core.dart';
import 'mhchem_texify.dart';

/// A supported upstream mhchemParser conversion mode.
enum MhchemMode {
  /// TeX input containing embedded `\ce` or `\pu` commands.
  tex,

  /// Chemical equation input.
  ce,

  /// Physical unit input.
  pu,
}

/// Why recursive embedded-command expansion failed.
enum MhchemExpansionFailure {
  /// Recognized commands remained after the configured number of passes.
  passLimit,

  /// A pass made no progress while recognized commands remained.
  noProgress,
}

/// A failure to completely expand embedded mhchem commands.
final class MhchemExpansionException implements Exception {
  /// Creates an expansion failure with diagnostic context.
  const MhchemExpansionException({
    required this.reason,
    required this.maxPasses,
    required this.passesCompleted,
    required this.lastOutput,
  });

  /// The termination condition that caused the failure.
  final MhchemExpansionFailure reason;

  /// The maximum number of passes requested by the caller.
  final int maxPasses;

  /// The number of conversion passes completed.
  final int passesCompleted;

  /// The last complete intermediate value, provided for diagnostics only.
  final String lastOutput;

  @override
  String toString() {
    return 'MhchemExpansionException('
        'reason: ${reason.name}, '
        'maxPasses: $maxPasses, '
        'passesCompleted: $passesCompleted)';
  }
}

/// Pure-Dart mhchemParser 4.2.2-compatible conversion entry points.
abstract final class MhchemParser {
  /// The independently versioned Dart package release.
  static const String packageVersion = '0.1.0';

  /// The upstream mhchemParser version implemented by this package.
  static const String upstreamVersion = '4.2.2';

  /// The immutable upstream commit used as the behavioral reference.
  static const String upstreamCommit =
      'acaf5adb97a08deb234e0a8d62c807c17ee650d6';

  /// Converts [input] exactly once using the selected upstream-compatible mode.
  static String convert(
    String input, {
    required MhchemMode mode,
  }) {
    final wireMode = mode.name;
    return MhchemTexify.go(
      MhchemParserCore.go(input, wireMode),
      mode != MhchemMode.tex,
    );
  }

  /// Legacy string-mode conversion retained throughout the 0.x release line.
  @Deprecated(
    'Use MhchemParser.convert(input, mode: MhchemMode.ce). '
    'This compatibility wrapper will not be removed before 1.0.0.',
  )
  static String toTex(String input, String type) {
    final mode = switch (type) {
      'tex' => MhchemMode.tex,
      'ce' => MhchemMode.ce,
      'pu' => MhchemMode.pu,
      _ => throw ArgumentError.value(
          type,
          'type',
          'Supported values are: tex, ce, pu.',
        ),
    };
    return convert(input, mode: mode);
  }

  /// Completely expands executable embedded `\ce` and `\pu` commands.
  ///
  /// The ordinary [convert] and [toTex] operations remain single-pass.
  static String expandAllTex(
    String input, {
    int maxPasses = 16,
  }) {
    if (maxPasses <= 0) {
      throw ArgumentError.value(
        maxPasses,
        'maxPasses',
        'Must be a positive integer.',
      );
    }

    var current = input;
    if (!_hasEmbeddedCommand(current)) {
      return current;
    }

    for (var pass = 1; pass <= maxPasses; pass++) {
      final next = convert(current, mode: MhchemMode.tex);
      if (next == current) {
        throw MhchemExpansionException(
          reason: MhchemExpansionFailure.noProgress,
          maxPasses: maxPasses,
          passesCompleted: pass,
          lastOutput: current,
        );
      }
      current = next;
      if (!_hasEmbeddedCommand(current)) {
        return current;
      }
    }

    throw MhchemExpansionException(
      reason: MhchemExpansionFailure.passLimit,
      maxPasses: maxPasses,
      passesCompleted: maxPasses,
      lastOutput: current,
    );
  }

  static bool _hasEmbeddedCommand(String input) {
    var index = 0;
    while (index < input.length) {
      if (input.codeUnitAt(index) != 0x5c) {
        index++;
        continue;
      }

      var runEnd = index;
      while (runEnd < input.length && input.codeUnitAt(runEnd) == 0x5c) {
        runEnd++;
      }
      final slashCount = runEnd - index;
      if (slashCount.isOdd &&
          (input.startsWith('ce{', runEnd) ||
              input.startsWith('pu{', runEnd))) {
        return true;
      }
      index = runEnd;
    }
    return false;
  }
}
