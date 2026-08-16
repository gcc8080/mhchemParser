import 'types.dart';

typedef PatternFn = MatchResult? Function(String input);

Map<String, List<Transition>> _createTransitions(
    Map<String, Map<String, dynamic>> o) {
  // 1. Collect all states
  final Map<String, List<Transition>> transitions = {};
  for (final pattern in o.keys) {
    final stateMap = o[pattern]!;
    for (final state in stateMap.keys) {
      final stateArray = state.split('|');
      for (final s in stateArray) {
        transitions[s] = [];
      }
    }
  }
  // 2. Fill states
  for (final pattern in o.keys) {
    final stateMap = o[pattern]!;
    for (final state in stateMap.keys) {
      final p = stateMap[state] as Map<String, dynamic>;
      final stateArray = state.split('|');
      for (int i = 0; i < stateArray.length; i++) {
        // 2a. Normalize actions into list of ActionEntry
        dynamic rawAction = p['action_'];
        List<dynamic> actionList;
        if (rawAction is List) {
          actionList = rawAction;
        } else {
          actionList = [rawAction];
        }
        final List<ActionEntry> actions = [];
        for (final a in actionList) {
          if (a is String) {
            actions.add(ActionEntry(a));
          } else if (a is ActionEntry) {
            actions.add(a);
          } else if (a is Map<String, dynamic>) {
            actions.add(ActionEntry(a['type_'] as String, a['option']));
          }
        }
        final task = Task(
          actions,
          nextState: p['nextState'] as String?,
          revisit: (p['revisit'] as bool?) ?? false,
          toContinue: (p['toContinue'] as bool?) ?? false,
        );
        // 2b. Multi-insert
        final patternArray = pattern.split('|');
        for (final pat in patternArray) {
          if (stateArray[i] == '*') {
            for (final t in transitions.keys.toList()) {
              transitions[t]!.add(Transition(pat, task));
            }
          } else {
            transitions[stateArray[i]]!.add(Transition(pat, task));
          }
        }
      }
    }
  }
  return transitions;
}

class MhchemParserCore {
  static List<Object> go(String? input, [String? stateMachine]) {
    if (input == null || input.isEmpty) return [];
    stateMachine ??= 'ce';
    String state = '0';
    final buffer = Buffer();

    input = input.replaceAll('\n', ' ');
    input = input.replaceAll(RegExp(r'[\u2212\u2013\u2014\u2010]'), '-');
    input = input.replaceAll('\u2026', '...');

    String? lastInput;
    int watchdog = 10;
    final output = <Object>[];
    while (true) {
      if (lastInput != input) {
        watchdog = 10;
        lastInput = input;
      } else {
        watchdog--;
      }
      final machine = _stateMachines[stateMachine]!;
      final t = machine.transitions[state] ?? machine.transitions['*'] ?? [];
      iterateTransitions:
      for (int i = 0; i < t.length; i++) {
        final matches = _match(t[i].pattern, input!);
        if (matches != null) {
          final task = t[i].task;
          for (int iA = 0; iA < task.action_.length; iA++) {
            Object? o;
            final actionType = task.action_[iA].type_;
            final actionOption = task.action_[iA].option;
            if (machine.actions.containsKey(actionType)) {
              o = machine.actions[actionType]!(
                  buffer, matches.match_, actionOption);
            } else if (_globalActions.containsKey(actionType)) {
              o = _globalActions[actionType]!(
                  buffer, matches.match_, actionOption);
            } else {
              throw MhchemError(
                  'MhchemBugA', 'mhchem bug A. Please report. ($actionType)');
            }
            concatArray(output, o);
          }
          state = task.nextState ?? state;
          if (input.isNotEmpty) {
            if (!task.revisit) {
              input = matches.remainder;
            }
            if (!task.toContinue) {
              break iterateTransitions;
            }
          } else {
            return output;
          }
        }
      }
      if (watchdog <= 0) {
        throw MhchemError('MhchemBugU', 'mhchem bug U. Please report.');
      }
    }
  }

  static void concatArray(List<Object> a, Object? b) {
    if (b != null) {
      if (b is List) {
        for (int i = 0; i < b.length; i++) {
          a.add(b[i] as Object);
        }
      } else {
        a.add(b);
      }
    }
  }

  // ============================================================
  // Patterns
  // ============================================================

  static String? _matchHelper(String input, Object pattern) {
    if (pattern is String) {
      if (pattern.isEmpty) return '';
      if (!input.startsWith(pattern)) return null;
      return pattern;
    } else {
      final match = (pattern as RegExp).firstMatch(input);
      if (match == null) return null;
      return match.group(0)!;
    }
  }

  static MatchResult? _findObserveGroups(String input, Object begExcl,
      Object begIncl, Object endIncl, Object endExcl,
      [Object? beg2Excl,
      Object? beg2Incl,
      Object? end2Incl,
      Object? end2Excl,
      bool combine = false]) {
    var match = _matchHelper(input, begExcl);
    if (match == null) return null;
    input = input.substring(match.length);
    match = _matchHelper(input, begIncl);
    if (match == null) return null;
    final endChars =
        (endIncl is String && endIncl.isNotEmpty) ? endIncl : endExcl;
    final e = _findObserveGroupsInner(input, match.length, endChars);
    if (e == null) return null;
    final match1 = input.substring(
        0, (endIncl is String && endIncl.isNotEmpty) ? e[1] : e[0]);
    if (beg2Excl == null && beg2Incl == null) {
      return MatchResult(match1, input.substring(e[1]));
    } else {
      final group2 = _findObserveGroups(input.substring(e[1]), beg2Excl ?? '',
          beg2Incl ?? '', end2Incl ?? '', end2Excl ?? '');
      if (group2 == null) return null;
      final List<String> matchRet = [match1, group2.match_ as String];
      return MatchResult(
          combine ? matchRet.join('') : matchRet, group2.remainder);
    }
  }

  static List<int>? _findObserveGroupsInner(
      String input, int i, Object endChars) {
    int braces = 0;
    while (i < input.length) {
      final match = _matchHelper(input.substring(i), endChars);
      if (match != null && braces == 0) {
        return [i, i + match.length];
      } else if (input[i] == '{') {
        braces++;
      } else if (input[i] == '}') {
        if (braces == 0) {
          throw MhchemError('ExtraCloseMissingOpen',
              'Extra close brace or missing open brace');
        } else {
          braces--;
        }
      }
      i++;
    }
    return null;
  }

  static MatchResult? _match(String patternName, String input) {
    final pattern = _patterns[patternName];
    if (pattern == null) {
      throw MhchemError(
          'MhchemBugP', 'mhchem bug P. Please report. ($patternName)');
    }
    if (pattern is PatternFn) {
      return pattern(input);
    }
    // RegExp
    final regExp = pattern as RegExp;
    final m = regExp.firstMatch(input);
    if (m != null) {
      if (m.groupCount > 1) {
        final groups = <String>[];
        for (int i = 1; i <= m.groupCount; i++) {
          groups.add(m.group(i) ?? '');
        }
        return MatchResult(groups, input.substring(m.end));
      } else {
        final match1 = m.groupCount >= 1 ? m.group(1) : null;
        return MatchResult(match1 ?? m.group(0)!, input.substring(m.end));
      }
    }
    return null;
  }

  static final Map<String, Object> _patterns = {
    'empty': RegExp(r'^$'),
    'else': RegExp(r'^.'),
    'else2': RegExp(r'^.'),
    'space': RegExp(r'^\s'),
    'space A': RegExp(r'^\s(?=[A-Z\\$])'),
    'space\$': RegExp(r'^\s$'),
    'a-z': RegExp(r'^[a-z]'),
    'x': RegExp(r'^x'),
    'x\$': RegExp(r'^x$'),
    'i\$': RegExp(r'^i$'),
    'letters': RegExp(
        r'^(?:[a-zA-Z\u03B1-\u03C9\u0391-\u03A9?@]|(?:\\(?:alpha|beta|gamma|delta|epsilon|zeta|eta|theta|iota|kappa|lambda|mu|nu|xi|omicron|pi|rho|sigma|tau|upsilon|phi|chi|psi|omega|Gamma|Delta|Theta|Lambda|Xi|Pi|Sigma|Upsilon|Phi|Psi|Omega)(?:\s+|\{\}|(?![a-zA-Z]))))+'),
    '\\greek': RegExp(
        r'^\\(?:alpha|beta|gamma|delta|epsilon|zeta|eta|theta|iota|kappa|lambda|mu|nu|xi|omicron|pi|rho|sigma|tau|upsilon|phi|chi|psi|omega|Gamma|Delta|Theta|Lambda|Xi|Pi|Sigma|Upsilon|Phi|Psi|Omega)(?:\s+|\{\}|(?![a-zA-Z]))'),
    'one lowercase latin letter \$': RegExp(r'^(?:([a-z])(?:$|[^a-zA-Z]))$'),
    '\$one lowercase latin letter\$ \$':
        RegExp(r'^\$(?:([a-z])(?:$|[^a-zA-Z]))\$$'),
    'one lowercase greek letter \$': RegExp(
        r'^(?:\$?[\u03B1-\u03C9]\$?|\$?\\(?:alpha|beta|gamma|delta|epsilon|zeta|eta|theta|iota|kappa|lambda|mu|nu|xi|omicron|pi|rho|sigma|tau|upsilon|phi|chi|psi|omega)\s*\$?)(?:\s+|\{\}|(?![a-zA-Z]))$'),
    'digits': RegExp(r'^[0-9]+'),
    '-9.,9': RegExp(r'^[+\-]?(?:[0-9]+(?:[,.][0-9]+)?|[0-9]*(?:\.[0-9]+))'),
    '-9.,9 no missing 0': RegExp(r'^[+\-]?[0-9]+(?:[.,][0-9]+)?'),
    '(-)(9.,9)(e)(99)': (String input) {
      final m = RegExp(
              r'^(\+\-|\+\/\-|\+|\-|\\pm\s?)?([0-9]+(?:[,.][0-9]+)?|[0-9]*(?:\.[0-9]+))?(\((?:[0-9]+(?:[,.][0-9]+)?|[0-9]*(?:\.[0-9]+))\))?(?:(?:([eE])|\s*(\*|x|\\times|\u00D7)\s*10\^)([+\-]?[0-9]+|\{[+\-]?[0-9]+\}))?')
          .firstMatch(input);
      if (m != null && m.group(0)!.isNotEmpty) {
        final groups = <String>[];
        for (int i = 1; i <= m.groupCount; i++) {
          groups.add(m.group(i) ?? '');
        }
        return MatchResult(groups, input.substring(m.end));
      }
      return null;
    },
    '(-)(9)^(-9)': RegExp(
        r'^(\+\-|\+\/\-|\+|\-|\\pm\s?)?([0-9]+(?:[,.][0-9]+)?|[0-9]*(?:\.[0-9]+)?)\^([+\-]?[0-9]+|\{[+\-]?[0-9]+\})'),
    'state of aggregation \$': (String input) {
      final a = _findObserveGroups(
          input, '', RegExp(r'^\([a-z]{1,3}(?=[\),])'), ')', '');
      if (a != null && RegExp(r'^($|[\s,;\)\]\}])').hasMatch(a.remainder)) {
        return a;
      }
      final m = RegExp(r'^(?:\((?:\\ca\s?)?\$[amothc]\$\))').firstMatch(input);
      if (m != null) {
        return MatchResult(m.group(0)!, input.substring(m.end));
      }
      return null;
    },
    '_{(state of aggregation)}\$': RegExp(r'^_\{(\([a-z]{1,3}\))\}'),
    '{[(': RegExp(r'^(?:\\\{|\[|\()'),
    ')]}': RegExp(r'^(?:\)|\]|\\\})'),
    ', ': RegExp(r'^[,;]\s*'),
    ',': RegExp(r'^[,;]'),
    '.': RegExp(r'^[.]'),
    '. __* ': RegExp(r'^([.\u22C5\u00B7\u2022]|[*])\s*'),
    '...': RegExp(r'^\.\.\.(?=$|[^.])'),
    '^{(...)}': (String input) {
      return _findObserveGroups(input, '^{', '', '', '}');
    },
    '^(\$...\$)': (String input) {
      return _findObserveGroups(input, '^', r'$', r'$', '');
    },
    '^a': RegExp(r'^\^([0-9]+|[^\\_])'),
    '^\\x{}{}': (String input) {
      return _findObserveGroups(input, '^', RegExp(r'^\\[a-zA-Z]+\{'), '}', '',
          '', '{', '}', '', true);
    },
    '^\\x{}': (String input) {
      return _findObserveGroups(input, '^', RegExp(r'^\\[a-zA-Z]+\{'), '}', '');
    },
    '^\\x': RegExp(r'^\^(\\[a-zA-Z]+)\s*'),
    '^(-1)': RegExp(r'^\^(-?\d+)'),
    "'": RegExp(r"^'"),
    '_{(...)}': (String input) {
      return _findObserveGroups(input, '_{', '', '', '}');
    },
    '_(\$...\$)': (String input) {
      return _findObserveGroups(input, '_', r'$', r'$', '');
    },
    '_9': RegExp(r'^_([+\-]?[0-9]+|[^\\])'),
    '_\\x{}{}': (String input) {
      return _findObserveGroups(input, '_', RegExp(r'^\\[a-zA-Z]+\{'), '}', '',
          '', '{', '}', '', true);
    },
    '_\\x{}': (String input) {
      return _findObserveGroups(input, '_', RegExp(r'^\\[a-zA-Z]+\{'), '}', '');
    },
    '_\\x': RegExp(r'^_(\\[a-zA-Z]+)\s*'),
    '^_': RegExp(r'^(?:\^(?=_)|\_(?=\^)|[\^_]$)'),
    '{}^': RegExp(r'^\{\}(?=\^)'),
    '{}': RegExp(r'^\{\}'),
    '{...}': (String input) {
      return _findObserveGroups(input, '', '{', '}', '');
    },
    '{(...)}': (String input) {
      return _findObserveGroups(input, '{', '', '', '}');
    },
    '\$...\$': (String input) {
      return _findObserveGroups(input, '', r'$', r'$', '');
    },
    '\${(...)}\$__\$(...)': (String input) {
      return _findObserveGroups(input, r'${', '', '', r'}$') ??
          _findObserveGroups(input, r'$', '', '', r'$');
    },
    '=<>': RegExp(r'^[=<>]'),
    '#': RegExp(r'^[#\u2261]'),
    '+': RegExp(r'^\+'),
    '-\$': RegExp(r'^-(?=[\s_},;\]/]|$|\([a-z]+\))'),
    '-9': RegExp(r'^-(?=[0-9])'),
    '- orbital overlap': RegExp(r'^-(?=(?:[spd]|sp)(?:$|[\s,;\)\]\}]))'),
    '-': RegExp(r'^-'),
    'pm-operator': RegExp(r'^(?:\\pm|\$\\pm\$|\+-|\+\/-)'),
    'operator': RegExp(
        r'^(?:\+|(?:[\-=<>]|<<|>>|\\approx|\$\\approx\$)(?=\s|$|-?[0-9]))'),
    'arrowUpDown': RegExp(r'^(?:v|\(v\)|\^|\(\^\))(?=$|[\s,;\)\]\}])'),
    '\\bond{(...)}': (String input) {
      return _findObserveGroups(input, '\\bond{', '', '', '}');
    },
    '->': RegExp(r'^(?:<->|<-->|->|<-|<=>>|<<=>|<=>|[\u2192\u27F6\u21CC])'),
    'CMT': RegExp(r'^[CMT](?=\[)'),
    '[(...)]': (String input) {
      return _findObserveGroups(input, '[', '', '', ']');
    },
    '1st-level escape': RegExp(r'^(&|\\\\|\\hline)\s*'),
    '\\,': RegExp(r'^(?:\\[,\ ;:])'),
    '\\x{}{}': (String input) {
      return _findObserveGroups(input, '', RegExp(r'^\\[a-zA-Z]+\{'), '}', '',
          '', '{', '}', '', true);
    },
    '\\x{}': (String input) {
      return _findObserveGroups(input, '', RegExp(r'^\\[a-zA-Z]+\{'), '}', '');
    },
    '\\ca': RegExp(r'^\\ca(?:\s+|(?![a-zA-Z]))'),
    '\\x': RegExp(r'^(?:\\[a-zA-Z]+\s*|\\[_&{}%])'),
    'orbital': RegExp(r'^(?:[0-9]{1,2}[spdfgh]|[0-9]{0,2}sp)(?=$|[^a-zA-Z])'),
    'others': RegExp(r'^[\/~|]'),
    '\\frac{(...)}': (String input) {
      return _findObserveGroups(
          input, '\\frac{', '', '', '}', '{', '', '', '}');
    },
    '\\overset{(...)}': (String input) {
      return _findObserveGroups(
          input, '\\overset{', '', '', '}', '{', '', '', '}');
    },
    '\\underset{(...)}': (String input) {
      return _findObserveGroups(
          input, '\\underset{', '', '', '}', '{', '', '', '}');
    },
    '\\underbrace{(...)}': (String input) {
      return _findObserveGroups(
          input, '\\underbrace{', '', '', '}_', '{', '', '', '}');
    },
    '\\color{(...)}': (String input) {
      return _findObserveGroups(input, '\\color{', '', '', '}');
    },
    '\\color{(...)}{(...)}': (String input) {
      return _findObserveGroups(
              input, '\\color{', '', '', '}', '{', '', '', '}') ??
          _findObserveGroups(
              input, '\\color', '\\', '', RegExp(r'^(?=\{)'), '{', '', '', '}');
    },
    '\\ce{(...)}': (String input) {
      return _findObserveGroups(input, '\\ce{', '', '', '}');
    },
    '\\pu{(...)}': (String input) {
      return _findObserveGroups(input, '\\pu{', '', '', '}');
    },
    'oxidation\$': RegExp(r'^(?:[+-][IVX]+|(?:\\pm|\$\\pm\$|\+-|\+\/-)\s*0)$'),
    'd-oxidation\$':
        RegExp(r'^(?:[+-]?[IVX]+|(?:\\pm|\$\\pm\$|\+-|\+\/-)\s*0)$'),
    '1/2\$': RegExp(
        r'^[+\-]?(?:[0-9]+|\$[a-z]\$|[a-z])\/[0-9]+(?:\$[a-z]\$|[a-z])?$'),
    'amount': _amountPattern,
    'amount2': (String input) {
      return _amountPattern(input);
    },
    '(KV letters),': RegExp(r'^(?:[A-Z][a-z]{0,2}|i)(?=,)'),
    'formula\$': (String input) {
      if (RegExp(r'^\([a-z]+\)$').hasMatch(input)) return null;
      final m = RegExp(
              r'^(?:[a-z]|(?:[0-9\ \+\-\,\.\(\)]+[a-z])+[0-9\ \+\-\,\.\(\)]*|(?:[a-z][0-9\ \+\-\,\.\(\)]+)+[a-z]?)$')
          .firstMatch(input);
      if (m != null) {
        return MatchResult(m.group(0)!, input.substring(m.end));
      }
      return null;
    },
    'uprightEntities': RegExp(r'^(?:pH|pOH|pC|pK|iPr|iBu)(?=$|[^a-zA-Z])'),
    '/': RegExp(r'^\s*(\/)\s*'),
    '//': RegExp(r'^\s*(\/\/)\s*'),
    '*': RegExp(r'^\s*[*.]\s*'),
    '{[(|)]}': RegExp(r'^(?:\\\{|\[|\(|\)|\]|\\\})'),
  };

  static MatchResult? _amountPattern(String input) {
    var m = RegExp(
            r'^(?:(?:(?:\([+\-]?[0-9]+\/[0-9]+\)|[+\-]?(?:[0-9]+|\$[a-z]\$|[a-z])\/[0-9]+|[+\-]?[0-9]+[.,][0-9]+|[+\-]?\.[0-9]+|[+\-]?[0-9]+)(?:[a-z](?=\s*[A-Z]))?)|[+\-]?[a-z](?=\s*[A-Z])|\+(?!\s))')
        .firstMatch(input);
    if (m != null) {
      return MatchResult(m.group(0)!, input.substring(m.end));
    }
    final a = _findObserveGroups(input, '', r'$', r'$', '');
    if (a != null) {
      m = RegExp(
              r'^\$(?:\(?[+\-]?(?:[0-9]*[a-z]?[+\-])?[0-9]*[a-z](?:[+\-][0-9]*[a-z]?)?\)?|\+|-)\$$')
          .firstMatch(a.match_ as String);
      if (m != null) {
        return MatchResult(m.group(0)!, input.substring(m.end));
      }
    }
    return null;
  }

  // ============================================================
  // Global Actions
  // ============================================================

  static final Map<String, ActionFn> _globalActions = {
    'a=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.a = (buffer.a ?? '') + (m as String);
      return null;
    },
    'b=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.b = (buffer.b ?? '') + (m as String);
      return null;
    },
    'p=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.p = (buffer.p ?? '') + (m as String);
      return null;
    },
    'o=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.o = (buffer.o ?? '') + (m as String);
      return null;
    },
    'o=+p1': (Buffer buffer, dynamic m, dynamic option) {
      buffer.o = (buffer.o ?? '') + (option as String);
      return null;
    },
    'q=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.q = (buffer.q ?? '') + (m as String);
      return null;
    },
    'd=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.d = (buffer.d ?? '') + (m as String);
      return null;
    },
    'rm=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.rm = (buffer.rm ?? '') + (m as String);
      return null;
    },
    'text=': (Buffer buffer, dynamic m, dynamic option) {
      buffer.text_ = (buffer.text_ ?? '') + (m as String);
      return null;
    },
    'insert': (Buffer buffer, dynamic m, dynamic option) {
      return {'type_': option as String};
    },
    'insert+p1': (Buffer buffer, dynamic m, dynamic option) {
      return {'type_': option as String, 'p1': m};
    },
    'insert+p1+p2': (Buffer buffer, dynamic m, dynamic option) {
      return {'type_': option as String, 'p1': (m as List)[0], 'p2': m[1]};
    },
    'copy': (Buffer buffer, dynamic m, dynamic option) {
      return m;
    },
    'write': (Buffer buffer, dynamic m, dynamic option) {
      return option as String;
    },
    'rm': (Buffer buffer, dynamic m, dynamic option) {
      return {'type_': 'rm', 'p1': m};
    },
    'text': (Buffer buffer, dynamic m, dynamic option) {
      return go(m as String, 'text');
    },
    'tex-math': (Buffer buffer, dynamic m, dynamic option) {
      return go(m as String, 'tex-math');
    },
    'tex-math tight': (Buffer buffer, dynamic m, dynamic option) {
      return go(m as String, 'tex-math tight');
    },
    'bond': (Buffer buffer, dynamic m, dynamic option) {
      return {'type_': 'bond', 'kind_': option ?? m};
    },
    'color0-output': (Buffer buffer, dynamic m, dynamic option) {
      return {'type_': 'color0', 'color': m};
    },
    'ce': (Buffer buffer, dynamic m, dynamic option) {
      return go(m as String, 'ce');
    },
    'pu': (Buffer buffer, dynamic m, dynamic option) {
      return go(m as String, 'pu');
    },
    '1/2': (Buffer buffer, dynamic m, dynamic option) {
      final ret = <Object>[];
      String ms = m as String;
      if (RegExp(r'^[+\-]').hasMatch(ms)) {
        ret.add(ms.substring(0, 1));
        ms = ms.substring(1);
      }
      final n =
          RegExp(r'^([0-9]+|\$[a-z]\$|[a-z])\/([0-9]+)(\$[a-z]\$|[a-z])?$')
              .firstMatch(ms)!;
      String n1 = n.group(1)!.replaceAll(r'$', '');
      ret.add({'type_': 'frac', 'p1': n1, 'p2': n.group(2)!});
      if (n.group(3) != null) {
        String n3 = n.group(3)!.replaceAll(r'$', '');
        ret.add({'type_': 'tex-math', 'p1': n3});
      }
      return ret;
    },
    '9,9': (Buffer buffer, dynamic m, dynamic option) {
      return go(m as String, '9,9');
    },
  };

  // ============================================================
  // State Machines
  // ============================================================

  // --- ce local actions ---

  static Object? _ceOutput(Buffer buffer, dynamic m, dynamic entityFollows) {
    Object ret;
    if (buffer.r == null) {
      final retList = <Object>[];
      if (buffer.a == null &&
          buffer.b == null &&
          buffer.p == null &&
          buffer.o == null &&
          buffer.q == null &&
          buffer.d == null &&
          entityFollows == null) {
        // ret = [];
      } else {
        if (buffer.sb) {
          retList.add({'type_': 'entitySkip'});
        }
        if (buffer.o == null &&
            buffer.q == null &&
            buffer.d == null &&
            buffer.b == null &&
            buffer.p == null &&
            entityFollows != 2) {
          buffer.o = buffer.a;
          buffer.a = null;
        } else if (buffer.o == null &&
            buffer.q == null &&
            buffer.d == null &&
            (buffer.b != null || buffer.p != null)) {
          buffer.o = buffer.a;
          buffer.d = buffer.b;
          buffer.q = buffer.p;
          buffer.a = buffer.b = buffer.p = null;
        } else {
          if (buffer.o != null &&
              buffer.dType == 'kv' &&
              _match('d-oxidation\$', buffer.d ?? '') != null) {
            buffer.dType = 'oxidation';
          } else if (buffer.o != null &&
              buffer.dType == 'kv' &&
              buffer.q == null) {
            buffer.dType = null;
          }
        }
        retList.add({
          'type_': 'chemfive',
          'a': go(buffer.a, 'a'),
          'b': go(buffer.b, 'bd'),
          'p': go(buffer.p, 'pq'),
          'o': go(buffer.o, 'o'),
          'q': go(buffer.q, 'pq'),
          'd': go(buffer.d, buffer.dType == 'oxidation' ? 'oxidation' : 'bd'),
          'dType': buffer.dType,
        });
      }
      ret = retList;
    } else {
      List<Object> rd;
      if (buffer.rdt == 'M') {
        rd = go(buffer.rd, 'tex-math');
      } else if (buffer.rdt == 'T') {
        rd = [
          {'type_': 'text', 'p1': buffer.rd ?? ''}
        ];
      } else {
        rd = go(buffer.rd, 'ce');
      }
      List<Object> rq;
      if (buffer.rqt == 'M') {
        rq = go(buffer.rq, 'tex-math');
      } else if (buffer.rqt == 'T') {
        rq = [
          {'type_': 'text', 'p1': buffer.rq ?? ''}
        ];
      } else {
        rq = go(buffer.rq, 'ce');
      }
      ret = {
        'type_': 'arrow',
        'r': buffer.r,
        'rd': rd,
        'rq': rq,
      };
    }
    buffer.clear();
    return ret;
  }

  static Object? _ceOAfterD(Buffer buffer, dynamic m, dynamic option) {
    List<Object> ret;
    if (RegExp(r'^[1-9][0-9]*$').hasMatch(buffer.d ?? '')) {
      final tmp = buffer.d;
      buffer.d = null;
      ret = _ceOutput(buffer, null, null) as List<Object>;
      ret.add({'type_': 'tinySkip'});
      buffer.b = tmp;
    } else {
      ret = _ceOutput(buffer, null, null) as List<Object>;
    }
    _globalActions['o=']!(buffer, m, null);
    return ret;
  }

  static Object? _ceChargeOrBond(Buffer buffer, dynamic m, dynamic option) {
    if (buffer.beginsWithBond) {
      final ret = <Object>[];
      concatArray(ret, _ceOutput(buffer, null, null));
      concatArray(ret, _globalActions['bond']!(buffer, m, '-'));
      return ret;
    } else {
      buffer.d = m as String;
      return null;
    }
  }

  static Object? _ceMinusAfterOD(Buffer buffer, dynamic m, dynamic isAfterD) {
    var c1 = _match('orbital', buffer.o ?? '');
    final c2 = _match('one lowercase greek letter \$', buffer.o ?? '');
    final c3 = _match('one lowercase latin letter \$', buffer.o ?? '');
    final c4 = _match('\$one lowercase latin letter\$ \$', buffer.o ?? '');
    final hyphenFollows = m == '-' &&
        ((c1 != null && c1.remainder == '') ||
            c2 != null ||
            c3 != null ||
            c4 != null);
    if (hyphenFollows &&
        buffer.a == null &&
        buffer.b == null &&
        buffer.p == null &&
        buffer.d == null &&
        buffer.q == null &&
        c1 == null &&
        c3 != null) {
      buffer.o = '\$${buffer.o}\$';
    }
    final ret = <Object>[];
    if (hyphenFollows) {
      concatArray(ret, _ceOutput(buffer, null, null));
      ret.add({'type_': 'hyphen'});
    } else {
      c1 = _match('digits', buffer.d ?? '');
      if (isAfterD == true && c1 != null && c1.remainder == '') {
        concatArray(ret, _globalActions['d=']!(buffer, m, null));
        concatArray(ret, _ceOutput(buffer, null, null));
      } else {
        concatArray(ret, _ceOutput(buffer, null, null));
        concatArray(ret, _globalActions['bond']!(buffer, m, '-'));
      }
    }
    return ret;
  }

  static late final Map<String, StateMachine> _stateMachines =
      _buildStateMachines();

  static Map<String, StateMachine> _buildStateMachines() {
    return {
      // TeX state machine
      'tex': StateMachine(
        _createTransitions({
          'empty': {
            '0': {'action_': 'copy'}
          },
          '\\ce{(...)}': {
            '0': {
              'action_': [
                {'type_': 'write', 'option': '{'},
                'ce',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '\\pu{(...)}': {
            '0': {
              'action_': [
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          'else': {
            '0': {'action_': 'copy'}
          },
        }),
        {},
      ),

      // ce state machine (main parser)
      'ce': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'output'}
          },
          'else': {
            '0|1|2': {
              'action_': 'beginsWithBond=false',
              'revisit': true,
              'toContinue': true,
            }
          },
          'oxidation\$': {
            '0': {'action_': 'oxidation-output'}
          },
          'CMT': {
            'r': {'action_': 'rdt=', 'nextState': 'rt'},
            'rd': {'action_': 'rqt=', 'nextState': 'rdt'},
          },
          'arrowUpDown': {
            '0|1|2|as': {
              'action_': ['sb=false', 'output', 'operator'],
              'nextState': '1',
            }
          },
          'uprightEntities': {
            '0|1|2': {
              'action_': ['o=', 'output'],
              'nextState': '1',
            }
          },
          'orbital': {
            '0|1|2|3': {'action_': 'o=', 'nextState': 'o'}
          },
          '->': {
            '0|1|2|3': {'action_': 'r=', 'nextState': 'r'},
            'a|as': {
              'action_': ['output', 'r='],
              'nextState': 'r',
            },
            '*': {
              'action_': ['output', 'r='],
              'nextState': 'r',
            },
          },
          '+': {
            'o': {'action_': 'd= kv', 'nextState': 'd'},
            'd|D': {'action_': 'd=', 'nextState': 'd'},
            'q': {'action_': 'd=', 'nextState': 'qd'},
            'qd|qD': {'action_': 'd=', 'nextState': 'qd'},
            'dq': {
              'action_': ['output', 'd='],
              'nextState': 'd',
            },
            '3': {
              'action_': ['sb=false', 'output', 'operator'],
              'nextState': '0',
            },
          },
          'amount': {
            '0|2': {'action_': 'a=', 'nextState': 'a'}
          },
          'pm-operator': {
            '0|1|2|a|as': {
              'action_': [
                'sb=false',
                'output',
                {'type_': 'operator', 'option': '\\pm'},
              ],
              'nextState': '0',
            }
          },
          'operator': {
            '0|1|2|a|as': {
              'action_': ['sb=false', 'output', 'operator'],
              'nextState': '0',
            }
          },
          '-\$': {
            'o|q': {
              'action_': ['charge or bond', 'output'],
              'nextState': 'qd',
            },
            'd': {'action_': 'd=', 'nextState': 'd'},
            'D': {
              'action_': [
                'output',
                {'type_': 'bond', 'option': '-'},
              ],
              'nextState': '3',
            },
            'q': {'action_': 'd=', 'nextState': 'qd'},
            'qd': {'action_': 'd=', 'nextState': 'qd'},
            'qD|dq': {
              'action_': [
                'output',
                {'type_': 'bond', 'option': '-'},
              ],
              'nextState': '3',
            },
          },
          '-9': {
            '3|o': {
              'action_': [
                'output',
                {'type_': 'insert', 'option': 'hyphen'},
              ],
              'nextState': '3',
            }
          },
          '- orbital overlap': {
            'o': {
              'action_': [
                'output',
                {'type_': 'insert', 'option': 'hyphen'},
              ],
              'nextState': '2',
            },
            'd': {
              'action_': [
                'output',
                {'type_': 'insert', 'option': 'hyphen'},
              ],
              'nextState': '2',
            },
          },
          '-': {
            '0|1|2': {
              'action_': [
                {'type_': 'output', 'option': 1},
                'beginsWithBond=true',
                {'type_': 'bond', 'option': '-'},
              ],
              'nextState': '3',
            },
            '3': {
              'action_': {'type_': 'bond', 'option': '-'}
            },
            'a': {
              'action_': [
                'output',
                {'type_': 'insert', 'option': 'hyphen'},
              ],
              'nextState': '2',
            },
            'as': {
              'action_': [
                {'type_': 'output', 'option': 2},
                {'type_': 'bond', 'option': '-'},
              ],
              'nextState': '3',
            },
            'b': {'action_': 'b='},
            'o': {
              'action_': {'type_': '- after o/d', 'option': false},
              'nextState': '2',
            },
            'q': {
              'action_': {'type_': '- after o/d', 'option': false},
              'nextState': '2',
            },
            'd|qd|dq': {
              'action_': {'type_': '- after o/d', 'option': true},
              'nextState': '2',
            },
            'D|qD|p': {
              'action_': [
                'output',
                {'type_': 'bond', 'option': '-'},
              ],
              'nextState': '3',
            },
          },
          'amount2': {
            '1|3': {'action_': 'a=', 'nextState': 'a'}
          },
          'letters': {
            '0|1|2|3|a|as|b|p|bp|o': {
              'action_': 'o=',
              'nextState': 'o',
            },
            'q|dq': {
              'action_': ['output', 'o='],
              'nextState': 'o',
            },
            'd|D|qd|qD': {'action_': 'o after d', 'nextState': 'o'},
          },
          'digits': {
            'o': {'action_': 'q=', 'nextState': 'q'},
            'd|D': {'action_': 'q=', 'nextState': 'dq'},
            'q': {
              'action_': ['output', 'o='],
              'nextState': 'o',
            },
            'a': {'action_': 'o=', 'nextState': 'o'},
          },
          'space A': {
            'b|p|bp': {'action_': <String>[]}
          },
          'space': {
            'a': {'action_': <String>[], 'nextState': 'as'},
            '0': {'action_': 'sb=false'},
            '1|2': {'action_': 'sb=true'},
            'r|rt|rd|rdt|rdq': {'action_': 'output', 'nextState': '0'},
            '*': {
              'action_': ['output', 'sb=true'],
              'nextState': '1',
            },
          },
          '1st-level escape': {
            '1|2': {
              'action_': [
                'output',
                {'type_': 'insert+p1', 'option': '1st-level escape'},
              ]
            },
            '*': {
              'action_': [
                'output',
                {'type_': 'insert+p1', 'option': '1st-level escape'},
              ],
              'nextState': '0',
            },
          },
          '[(...)]': {
            'r|rt': {'action_': 'rd=', 'nextState': 'rd'},
            'rd|rdt': {'action_': 'rq=', 'nextState': 'rdq'},
          },
          '...': {
            'o|d|D|dq|qd|qD': {
              'action_': [
                'output',
                {'type_': 'bond', 'option': '...'},
              ],
              'nextState': '3',
            },
            '*': {
              'action_': [
                {'type_': 'output', 'option': 1},
                {'type_': 'insert', 'option': 'ellipsis'},
              ],
              'nextState': '1',
            },
          },
          '. __* ': {
            '*': {
              'action_': [
                'output',
                {'type_': 'insert', 'option': 'addition compound'},
              ],
              'nextState': '1',
            }
          },
          'state of aggregation \$': {
            '*': {
              'action_': ['output', 'state of aggregation'],
              'nextState': '1',
            }
          },
          '{[(': {
            'a|as|o': {
              'action_': ['o=', 'output', 'parenthesisLevel++'],
              'nextState': '2',
            },
            '0|1|2|3': {
              'action_': ['o=', 'output', 'parenthesisLevel++'],
              'nextState': '2',
            },
            '*': {
              'action_': ['output', 'o=', 'output', 'parenthesisLevel++'],
              'nextState': '2',
            },
          },
          ')]}': {
            '0|1|2|3|b|p|bp|o': {
              'action_': ['o=', 'parenthesisLevel--'],
              'nextState': 'o',
            },
            'a|as|d|D|q|qd|qD|dq': {
              'action_': ['output', 'o=', 'parenthesisLevel--'],
              'nextState': 'o',
            },
          },
          ', ': {
            '*': {
              'action_': ['output', 'comma'],
              'nextState': '0',
            }
          },
          '^_': {
            '*': {'action_': <String>[]}
          },
          '^{(...)}|^(\$...\$)': {
            '0|1|2|as': {'action_': 'b=', 'nextState': 'b'},
            'p': {'action_': 'b=', 'nextState': 'bp'},
            '3|o': {'action_': 'd= kv', 'nextState': 'D'},
            'q': {'action_': 'd=', 'nextState': 'qD'},
            'd|D|qd|qD|dq': {
              'action_': ['output', 'd='],
              'nextState': 'D',
            },
          },
          "^a|^\\x{}{}|^\\x{}|^\\x|'": {
            '0|1|2|as': {'action_': 'b=', 'nextState': 'b'},
            'p': {'action_': 'b=', 'nextState': 'bp'},
            '3|o': {'action_': 'd= kv', 'nextState': 'd'},
            'q': {'action_': 'd=', 'nextState': 'qd'},
            'd|qd|D|qD': {'action_': 'd='},
            'dq': {
              'action_': ['output', 'd='],
              'nextState': 'd',
            },
          },
          '_{(state of aggregation)}\$': {
            'd|D|q|qd|qD|dq': {
              'action_': ['output', 'q='],
              'nextState': 'q',
            }
          },
          '_{(...)}|_(\$...\$)|_9|_\\x{}{}|_\\x{}|_\\x': {
            '0|1|2|as': {'action_': 'p=', 'nextState': 'p'},
            'b': {'action_': 'p=', 'nextState': 'bp'},
            '3|o': {'action_': 'q=', 'nextState': 'q'},
            'd|D': {'action_': 'q=', 'nextState': 'dq'},
            'q|qd|qD|dq': {
              'action_': ['output', 'q='],
              'nextState': 'q',
            },
          },
          '=<>': {
            '0|1|2|3|a|as|o|q|d|D|qd|qD|dq': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'bond',
              ],
              'nextState': '3',
            }
          },
          '#': {
            '0|1|2|3|a|as|o': {
              'action_': [
                {'type_': 'output', 'option': 2},
                {'type_': 'bond', 'option': '#'},
              ],
              'nextState': '3',
            }
          },
          '{}^': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 1},
                {'type_': 'insert', 'option': 'tinySkip'},
              ],
              'nextState': '1',
            }
          },
          '{}': {
            '*': {
              'action_': {'type_': 'output', 'option': 1},
              'nextState': '1',
            }
          },
          '{...}': {
            '0|1|2|3|a|as|b|p|bp': {
              'action_': 'o=',
              'nextState': 'o',
            },
            'o|d|D|q|qd|qD|dq': {
              'action_': ['output', 'o='],
              'nextState': 'o',
            },
          },
          '\$...\$': {
            'a': {'action_': 'a='},
            '0|1|2|3|as|b|p|bp|o': {
              'action_': 'o=',
              'nextState': 'o',
            },
            'as|o': {'action_': 'o='},
            'q|d|D|qd|qD|dq': {
              'action_': ['output', 'o='],
              'nextState': 'o',
            },
          },
          '\\bond{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'bond',
              ],
              'nextState': '3',
            }
          },
          '\\frac{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 1},
                'frac-output',
              ],
              'nextState': '3',
            }
          },
          '\\overset{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'overset-output',
              ],
              'nextState': '3',
            }
          },
          '\\underset{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'underset-output',
              ],
              'nextState': '3',
            }
          },
          '\\underbrace{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'underbrace-output',
              ],
              'nextState': '3',
            }
          },
          '\\color{(...)}{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'color-output',
              ],
              'nextState': '3',
            }
          },
          '\\color{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'color0-output',
              ]
            }
          },
          '\\ce{(...)}': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 2},
                'ce',
              ],
              'nextState': '3',
            }
          },
          '\\,': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 1},
                'copy',
              ],
              'nextState': '1',
            }
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                'output',
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ],
              'nextState': '3',
            }
          },
          '\\x{}{}|\\x{}|\\x': {
            '0|1|2|3|a|as|b|p|bp|o|c0': {
              'action_': ['o=', 'output'],
              'nextState': '3',
            },
            '*': {
              'action_': ['output', 'o=', 'output'],
              'nextState': '3',
            },
          },
          'others': {
            '*': {
              'action_': [
                {'type_': 'output', 'option': 1},
                'copy',
              ],
              'nextState': '3',
            }
          },
          'else2': {
            'a': {
              'action_': 'a to o',
              'nextState': 'o',
              'revisit': true,
            },
            'as': {
              'action_': ['output', 'sb=true'],
              'nextState': '1',
              'revisit': true,
            },
            'r|rt|rd|rdt|rdq': {
              'action_': ['output'],
              'nextState': '0',
              'revisit': true,
            },
            '*': {
              'action_': ['output', 'copy'],
              'nextState': '3',
            },
          },
        }),
        {
          'o after d': _ceOAfterD,
          'd= kv': (Buffer buffer, dynamic m, dynamic option) {
            buffer.d = m as String;
            buffer.dType = 'kv';
            return null;
          },
          'charge or bond': _ceChargeOrBond,
          '- after o/d': _ceMinusAfterOD,
          'a to o': (Buffer buffer, dynamic m, dynamic option) {
            buffer.o = buffer.a;
            buffer.a = null;
            return null;
          },
          'sb=true': (Buffer buffer, dynamic m, dynamic option) {
            buffer.sb = true;
            return null;
          },
          'sb=false': (Buffer buffer, dynamic m, dynamic option) {
            buffer.sb = false;
            return null;
          },
          'beginsWithBond=true': (Buffer buffer, dynamic m, dynamic option) {
            buffer.beginsWithBond = true;
            return null;
          },
          'beginsWithBond=false': (Buffer buffer, dynamic m, dynamic option) {
            buffer.beginsWithBond = false;
            return null;
          },
          'parenthesisLevel++': (Buffer buffer, dynamic m, dynamic option) {
            buffer.parenthesisLevel++;
            return null;
          },
          'parenthesisLevel--': (Buffer buffer, dynamic m, dynamic option) {
            buffer.parenthesisLevel--;
            return null;
          },
          'state of aggregation': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'state of aggregation',
              'p1': go(m as String, 'o'),
            };
          },
          'comma': (Buffer buffer, dynamic m, dynamic option) {
            final a = (m as String).replaceAll(RegExp(r'\s*$'), '');
            final withSpace = (a != m);
            if (withSpace && buffer.parenthesisLevel == 0) {
              return {'type_': 'comma enumeration L', 'p1': a};
            } else {
              return {'type_': 'comma enumeration M', 'p1': a};
            }
          },
          'output': _ceOutput,
          'oxidation-output': (Buffer buffer, dynamic m, dynamic option) {
            final ret = <Object>['{'];
            concatArray(ret, go(m as String, 'oxidation'));
            ret.add('}');
            return ret;
          },
          'frac-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'frac-ce',
              'p1': go((m as List)[0] as String, 'ce'),
              'p2': go(m[1] as String, 'ce'),
            };
          },
          'overset-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'overset',
              'p1': go((m as List)[0] as String, 'ce'),
              'p2': go(m[1] as String, 'ce'),
            };
          },
          'underset-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'underset',
              'p1': go((m as List)[0] as String, 'ce'),
              'p2': go(m[1] as String, 'ce'),
            };
          },
          'underbrace-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'underbrace',
              'p1': go((m as List)[0] as String, 'ce'),
              'p2': go(m[1] as String, 'ce'),
            };
          },
          'color-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'color',
              'color1': (m as List)[0],
              'color2': go(m[1] as String, 'ce'),
            };
          },
          'r=': (Buffer buffer, dynamic m, dynamic option) {
            buffer.r = m as String;
            return null;
          },
          'rdt=': (Buffer buffer, dynamic m, dynamic option) {
            buffer.rdt = m as String;
            return null;
          },
          'rd=': (Buffer buffer, dynamic m, dynamic option) {
            buffer.rd = m as String;
            return null;
          },
          'rqt=': (Buffer buffer, dynamic m, dynamic option) {
            buffer.rqt = m as String;
            return null;
          },
          'rq=': (Buffer buffer, dynamic m, dynamic option) {
            buffer.rq = m as String;
            return null;
          },
          'operator': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'operator', 'kind_': option ?? m};
          },
        },
      ),

      // 'a' state machine
      'a': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': <String>[]}
          },
          '1/2\$': {
            '0': {'action_': '1/2'}
          },
          'else': {
            '0': {'action_': <String>[], 'nextState': '1', 'revisit': true}
          },
          '\${(...)}\$__\$(...)': {
            '*': {'action_': 'tex-math tight', 'nextState': '1'}
          },
          ',': {
            '*': {
              'action_': {'type_': 'insert', 'option': 'commaDecimal'}
            }
          },
          'else2': {
            '*': {'action_': 'copy'}
          },
        }),
        {},
      ),

      // 'o' state machine
      'o': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': <String>[]}
          },
          '1/2\$': {
            '0': {'action_': '1/2'}
          },
          'else': {
            '0': {'action_': <String>[], 'nextState': '1', 'revisit': true}
          },
          'letters': {
            '*': {'action_': 'rm'}
          },
          '\\ca': {
            '*': {
              'action_': {'type_': 'insert', 'option': 'circa'}
            }
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '\\x{}{}|\\x{}|\\x': {
            '*': {'action_': 'copy'}
          },
          '\${(...)}\$__\$(...)': {
            '*': {'action_': 'tex-math'}
          },
          '{(...)}': {
            '*': {
              'action_': [
                {'type_': 'write', 'option': '{'},
                'text',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          'else2': {
            '*': {'action_': 'copy'}
          },
        }),
        {},
      ),

      // 'text' state machine
      'text': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'output'}
          },
          '{...}': {
            '*': {'action_': 'text='}
          },
          '\${(...)}\$__\$(...)': {
            '*': {'action_': 'tex-math'}
          },
          '\\greek': {
            '*': {
              'action_': ['output', 'rm']
            }
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                'output',
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '\\,|\\x{}{}|\\x{}|\\x': {
            '*': {
              'action_': ['output', 'copy']
            }
          },
          'else': {
            '*': {'action_': 'text='}
          },
        }),
        {
          'output': (Buffer buffer, dynamic m, dynamic option) {
            if (buffer.text_ != null) {
              final ret = {'type_': 'text', 'p1': buffer.text_};
              buffer.clearAll();
              return ret;
            }
            return null;
          },
        },
      ),

      // 'pq' state machine
      'pq': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': <String>[]}
          },
          'state of aggregation \$': {
            '*': {'action_': 'state of aggregation'}
          },
          'i\$': {
            '0': {'action_': <String>[], 'nextState': '!f', 'revisit': true}
          },
          '(KV letters),': {
            '0': {'action_': 'rm', 'nextState': '0'}
          },
          'formula\$': {
            '0': {'action_': <String>[], 'nextState': 'f', 'revisit': true}
          },
          '1/2\$': {
            '0': {'action_': '1/2'}
          },
          'else': {
            '0': {'action_': <String>[], 'nextState': '!f', 'revisit': true}
          },
          '\${(...)}\$__\$(...)': {
            '*': {'action_': 'tex-math'}
          },
          '{(...)}': {
            '*': {'action_': 'text'}
          },
          'a-z': {
            'f': {'action_': 'tex-math'}
          },
          'letters': {
            '*': {'action_': 'rm'}
          },
          '-9.,9': {
            '*': {'action_': '9,9'}
          },
          ',': {
            '*': {
              'action_': {'type_': 'insert+p1', 'option': 'comma enumeration S'}
            }
          },
          '\\color{(...)}{(...)}': {
            '*': {'action_': 'color-output'}
          },
          '\\color{(...)}': {
            '*': {'action_': 'color0-output'}
          },
          '\\ce{(...)}': {
            '*': {'action_': 'ce'}
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '\\,|\\x{}{}|\\x{}|\\x': {
            '*': {'action_': 'copy'}
          },
          'else2': {
            '*': {'action_': 'copy'}
          },
        }),
        {
          'state of aggregation': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'state of aggregation subscript',
              'p1': go(m as String, 'o'),
            };
          },
          'color-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'color',
              'color1': (m as List)[0],
              'color2': go(m[1] as String, 'pq'),
            };
          },
        },
      ),

      // 'bd' state machine
      'bd': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': <String>[]}
          },
          'x\$': {
            '0': {'action_': <String>[], 'nextState': '!f', 'revisit': true}
          },
          'formula\$': {
            '0': {'action_': <String>[], 'nextState': 'f', 'revisit': true}
          },
          'else': {
            '0': {'action_': <String>[], 'nextState': '!f', 'revisit': true}
          },
          '-9.,9 no missing 0': {
            '*': {'action_': '9,9'}
          },
          '.': {
            '*': {
              'action_': {'type_': 'insert', 'option': 'electron dot'}
            }
          },
          'a-z': {
            'f': {'action_': 'tex-math'}
          },
          'x': {
            '*': {
              'action_': {'type_': 'insert', 'option': 'KV x'}
            }
          },
          'letters': {
            '*': {'action_': 'rm'}
          },
          "'": {
            '*': {
              'action_': {'type_': 'insert', 'option': 'prime'}
            }
          },
          '\${(...)}\$__\$(...)': {
            '*': {'action_': 'tex-math'}
          },
          '{(...)}': {
            '*': {'action_': 'text'}
          },
          '\\color{(...)}{(...)}': {
            '*': {'action_': 'color-output'}
          },
          '\\color{(...)}': {
            '*': {'action_': 'color0-output'}
          },
          '\\ce{(...)}': {
            '*': {'action_': 'ce'}
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '\\,|\\x{}{}|\\x{}|\\x': {
            '*': {'action_': 'copy'}
          },
          'else2': {
            '*': {'action_': 'copy'}
          },
        }),
        {
          'color-output': (Buffer buffer, dynamic m, dynamic option) {
            return {
              'type_': 'color',
              'color1': (m as List)[0],
              'color2': go(m[1] as String, 'bd'),
            };
          },
        },
      ),

      // 'oxidation' state machine
      'oxidation': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'roman-numeral'}
          },
          'pm-operator': {
            '*': {
              'action_': {'type_': 'o=+p1', 'option': '\\pm'}
            }
          },
          'else': {
            '*': {'action_': 'o='}
          },
        }),
        {
          'roman-numeral': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'roman numeral', 'p1': buffer.o ?? ''};
          },
        },
      ),

      // 'tex-math' state machine
      'tex-math': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'output'}
          },
          '\\ce{(...)}': {
            '*': {
              'action_': ['output', 'ce']
            }
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                'output',
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '{...}|\\,|\\x{}{}|\\x{}|\\x': {
            '*': {'action_': 'o='}
          },
          'else': {
            '*': {'action_': 'o='}
          },
        }),
        {
          'output': (Buffer buffer, dynamic m, dynamic option) {
            if (buffer.o != null) {
              final ret = {'type_': 'tex-math', 'p1': buffer.o};
              buffer.clearAll();
              return ret;
            }
            return null;
          },
        },
      ),

      // 'tex-math tight' state machine
      'tex-math tight': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'output'}
          },
          '\\ce{(...)}': {
            '*': {
              'action_': ['output', 'ce']
            }
          },
          '\\pu{(...)}': {
            '*': {
              'action_': [
                'output',
                {'type_': 'write', 'option': '{'},
                'pu',
                {'type_': 'write', 'option': '}'},
              ]
            }
          },
          '{...}|\\,|\\x{}{}|\\x{}|\\x': {
            '*': {'action_': 'o='}
          },
          '-|+': {
            '*': {'action_': 'tight operator'}
          },
          'else': {
            '*': {'action_': 'o='}
          },
        }),
        {
          'tight operator': (Buffer buffer, dynamic m, dynamic option) {
            buffer.o = (buffer.o ?? '') + '{$m}';
            return null;
          },
          'output': (Buffer buffer, dynamic m, dynamic option) {
            if (buffer.o != null) {
              final ret = {'type_': 'tex-math', 'p1': buffer.o};
              buffer.clearAll();
              return ret;
            }
            return null;
          },
        },
      ),

      // '9,9' state machine
      '9,9': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': <String>[]}
          },
          ',': {
            '*': {'action_': 'comma'}
          },
          'else': {
            '*': {'action_': 'copy'}
          },
        }),
        {
          'comma': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'commaDecimal'};
          },
        },
      ),

      // 'pu' state machine
      'pu': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'output'}
          },
          'space\$': {
            '*': {
              'action_': ['output', 'space']
            }
          },
          '{[(|)]}': {
            '0|a': {'action_': 'copy'}
          },
          '(-)(9)^(-9)': {
            '0': {'action_': 'number^', 'nextState': 'a'}
          },
          '(-)(9.,9)(e)(99)': {
            '0': {'action_': 'enumber', 'nextState': 'a'}
          },
          'space': {
            '0|a': {'action_': <String>[]}
          },
          'pm-operator': {
            '0|a': {
              'action_': {'type_': 'operator', 'option': '\\pm'},
              'nextState': '0',
            }
          },
          'operator': {
            '0|a': {'action_': 'copy', 'nextState': '0'}
          },
          '//': {
            'd': {'action_': 'o=', 'nextState': '/'}
          },
          '/': {
            'd': {'action_': 'o=', 'nextState': '/'}
          },
          '{...}|else': {
            '0|d': {'action_': 'd=', 'nextState': 'd'},
            'a': {
              'action_': ['space', 'd='],
              'nextState': 'd',
            },
            '/|q': {'action_': 'q=', 'nextState': 'q'},
          },
        }),
        {
          'enumber': (Buffer buffer, dynamic m, dynamic option) {
            final ms = m as List;
            final ret = <Object>[];
            if (ms[0] == '+-' || ms[0] == '+/-') {
              ret.add('\\pm ');
            } else if ((ms[0] as String).isNotEmpty) {
              ret.add(ms[0] as String);
            }
            if ((ms[1] as String).isNotEmpty) {
              concatArray(ret, go(ms[1] as String, 'pu-9,9'));
              if ((ms[2] as String).isNotEmpty) {
                if (RegExp(r'[,.]').hasMatch(ms[2] as String)) {
                  concatArray(ret, go(ms[2] as String, 'pu-9,9'));
                } else {
                  ret.add(ms[2] as String);
                }
              }
              if ((ms[3] as String).isNotEmpty ||
                  (ms[4] as String).isNotEmpty) {
                if (ms[3] == 'e' || ms[4] == '*') {
                  ret.add({'type_': 'cdot'});
                } else {
                  ret.add({'type_': 'times'});
                }
              }
            }
            if ((ms[5] as String).isNotEmpty) {
              ret.add('10^{${ms[5]}}');
            }
            return ret;
          },
          'number^': (Buffer buffer, dynamic m, dynamic option) {
            final ms = m as List;
            final ret = <Object>[];
            if (ms[0] == '+-' || ms[0] == '+/-') {
              ret.add('\\pm ');
            } else if ((ms[0] as String).isNotEmpty) {
              ret.add(ms[0] as String);
            }
            concatArray(ret, go(ms[1] as String, 'pu-9,9'));
            ret.add('^{${ms[2]}}');
            return ret;
          },
          'operator': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'operator', 'kind_': option ?? m};
          },
          'space': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'pu-space-1'};
          },
          'output': (Buffer buffer, dynamic m, dynamic option) {
            Object ret;
            final md = _match('{(...)}', buffer.d ?? '');
            if (md != null && md.remainder == '') {
              buffer.d = md.match_ as String;
            }
            final mq = _match('{(...)}', buffer.q ?? '');
            if (mq != null && mq.remainder == '') {
              buffer.q = mq.match_ as String;
            }
            if (buffer.d != null) {
              buffer.d = buffer.d!
                  .replaceAll(RegExp(r'\u00B0C|\^oC|\^\{o\}C'), '{}^{\\circ}C');
              buffer.d = buffer.d!
                  .replaceAll(RegExp(r'\u00B0F|\^oF|\^\{o\}F'), '{}^{\\circ}F');
            }
            if (buffer.q != null) {
              buffer.q = buffer.q!
                  .replaceAll(RegExp(r'\u00B0C|\^oC|\^\{o\}C'), '{}^{\\circ}C');
              buffer.q = buffer.q!
                  .replaceAll(RegExp(r'\u00B0F|\^oF|\^\{o\}F'), '{}^{\\circ}F');
              final b5d = go(buffer.d, 'pu');
              final b5q = go(buffer.q, 'pu');
              if (buffer.o == '//') {
                ret = {'type_': 'pu-frac', 'p1': b5d, 'p2': b5q};
              } else {
                final retList = List<Object>.from(b5d);
                if (b5d.length > 1 || b5q.length > 1) {
                  retList.add({'type_': ' / '});
                } else {
                  retList.add({'type_': '/'});
                }
                concatArray(retList, b5q);
                ret = retList;
              }
            } else {
              ret = go(buffer.d, 'pu-2');
            }
            buffer.clearAll();
            return ret;
          },
        },
      ),

      // 'pu-2' state machine
      'pu-2': StateMachine(
        _createTransitions({
          'empty': {
            '*': {'action_': 'output'}
          },
          '*': {
            '*': {
              'action_': ['output', 'cdot'],
              'nextState': '0',
            }
          },
          '\\x': {
            '*': {'action_': 'rm='}
          },
          'space': {
            '*': {
              'action_': ['output', 'space'],
              'nextState': '0',
            }
          },
          '^{(...)}|^(-1)': {
            '1': {'action_': '^(-1)'}
          },
          '-9.,9': {
            '0': {'action_': 'rm=', 'nextState': '0'},
            '1': {'action_': '^(-1)', 'nextState': '0'},
          },
          '{...}|else': {
            '*': {'action_': 'rm=', 'nextState': '1'}
          },
        }),
        {
          'cdot': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'tight cdot'};
          },
          '^(-1)': (Buffer buffer, dynamic m, dynamic option) {
            buffer.rm = (buffer.rm ?? '') + '^{$m}';
            return null;
          },
          'space': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'pu-space-2'};
          },
          'output': (Buffer buffer, dynamic m, dynamic option) {
            Object ret = <Object>[];
            if (buffer.rm != null) {
              final mrm = _match('{(...)}', buffer.rm ?? '');
              if (mrm != null && mrm.remainder == '') {
                ret = go(mrm.match_ as String, 'pu');
              } else {
                ret = {'type_': 'rm', 'p1': buffer.rm};
              }
            }
            buffer.clearAll();
            return ret;
          },
        },
      ),

      // 'pu-9,9' state machine
      'pu-9,9': StateMachine(
        _createTransitions({
          'empty': {
            '0': {'action_': 'output-0'},
            'o': {'action_': 'output-o'},
          },
          ',': {
            '0': {
              'action_': ['output-0', 'comma'],
              'nextState': 'o',
            }
          },
          '.': {
            '0': {
              'action_': ['output-0', 'copy'],
              'nextState': 'o',
            }
          },
          'else': {
            '*': {'action_': 'text='}
          },
        }),
        {
          'comma': (Buffer buffer, dynamic m, dynamic option) {
            return {'type_': 'commaDecimal'};
          },
          'output-0': (Buffer buffer, dynamic m, dynamic option) {
            final ret = <Object>[];
            buffer.text_ = buffer.text_ ?? '';
            if (buffer.text_!.length > 4) {
              int a = buffer.text_!.length % 3;
              if (a == 0) a = 3;
              for (int i = buffer.text_!.length - 3; i > 0; i -= 3) {
                ret.add(buffer.text_!.substring(i, i + 3));
                ret.add({'type_': '1000 separator'});
              }
              ret.add(buffer.text_!.substring(0, a));
              ret.reversed.toList(); // need to actually reverse
              // Rewrite: reverse in-place
              final reversed = ret.reversed.toList();
              ret.clear();
              ret.addAll(reversed);
            } else {
              ret.add(buffer.text_!);
            }
            buffer.clearAll();
            return ret;
          },
          'output-o': (Buffer buffer, dynamic m, dynamic option) {
            final ret = <Object>[];
            buffer.text_ = buffer.text_ ?? '';
            if (buffer.text_!.length > 4) {
              final a = buffer.text_!.length - 3;
              int i;
              for (i = 0; i < a; i += 3) {
                ret.add(buffer.text_!.substring(i, i + 3));
                ret.add({'type_': '1000 separator'});
              }
              ret.add(buffer.text_!.substring(i));
            } else {
              ret.add(buffer.text_!);
            }
            buffer.clearAll();
            return ret;
          },
        },
      ),
    };
  }
}
