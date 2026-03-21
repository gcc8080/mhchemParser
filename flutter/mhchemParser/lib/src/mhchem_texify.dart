import 'types.dart';

class MhchemTexify {
  static String go(List? input, bool addOuterBraces) {
    if (input == null || input.isEmpty) return '';
    String res = '';
    bool cee = false;
    for (int i = 0; i < input.length; i++) {
      final inputi = input[i];
      if (inputi is String) {
        res += inputi;
      } else {
        final map = inputi as Map<String, dynamic>;
        res += _go2(map);
        if (map['type_'] == '1st-level escape') {
          cee = true;
        }
      }
    }
    if (addOuterBraces && !cee && res.isNotEmpty) {
      res = '{$res}';
    }
    return res;
  }

  static String _goInner(dynamic input) {
    return go(input as List?, false);
  }

  static String _go2(Map<String, dynamic> buf) {
    String res;
    switch (buf['type_'] as String) {
      case 'chemfive':
        res = '';
        String a = _goInner(buf['a']);
        String b = _goInner(buf['b']);
        String p = _goInner(buf['p']);
        String o = _goInner(buf['o']);
        String q = _goInner(buf['q']);
        String d = _goInner(buf['d']);
        // a
        if (a.isNotEmpty) {
          if (RegExp(r'^[+\-]').hasMatch(a)) {
            a = '{$a}';
          }
          res += '$a\\,';
        }
        // b and p
        if (b.isNotEmpty || p.isNotEmpty) {
          res += '{\\vphantom{A}}';
          res += '^{\\hphantom{$b}}_{\\hphantom{$p}}';
          res += '\\mkern-1.5mu';
          res += '{\\vphantom{A}}';
          res += '^{\\smash[t]{\\vphantom{2}}\\llap{$b}}';
          res += '_{\\vphantom{2}\\llap{\\smash[t]{$p}}}';
        }
        // o
        if (o.isNotEmpty) {
          if (RegExp(r'^[+\-]').hasMatch(o)) {
            o = '{$o}';
          }
          res += o;
        }
        // q and d
        if (buf['dType'] == 'kv') {
          if (d.isNotEmpty || q.isNotEmpty) {
            res += '{\\vphantom{A}}';
          }
          if (d.isNotEmpty) {
            res += '^{$d}';
          }
          if (q.isNotEmpty) {
            res += '_{\\smash[t]{$q}}';
          }
        } else if (buf['dType'] == 'oxidation') {
          if (d.isNotEmpty) {
            res += '{\\vphantom{A}}';
            res += '^{$d}';
          }
          if (q.isNotEmpty) {
            res += '{\\vphantom{A}}';
            res += '_{\\smash[t]{$q}}';
          }
        } else {
          if (q.isNotEmpty) {
            res += '{\\vphantom{A}}';
            res += '_{\\smash[t]{$q}}';
          }
          if (d.isNotEmpty) {
            res += '{\\vphantom{A}}';
            res += '^{$d}';
          }
        }
        break;
      case 'rm':
        res = '\\mathrm{${buf['p1']}}';
        break;
      case 'text':
        if (RegExp(r'[\^_]').hasMatch(buf['p1'] as String)) {
          String p1 = (buf['p1'] as String)
              .replaceAll(' ', '~')
              .replaceAll('-', '\\text{-}');
          res = '\\mathrm{$p1}';
        } else {
          res = '\\text{${buf['p1']}}';
        }
        break;
      case 'roman numeral':
        res = '\\mathrm{${buf['p1']}}';
        break;
      case 'state of aggregation':
        res = '\\mskip2mu ${_goInner(buf['p1'])}';
        break;
      case 'state of aggregation subscript':
        res = '\\mskip1mu ${_goInner(buf['p1'])}';
        break;
      case 'bond':
        res = _getBond(buf['kind_'] as String);
        if (res.isEmpty) {
          throw MhchemError('MhchemErrorBond',
              'mhchem Error. Unknown bond type (${buf['kind_']})');
        }
        break;
      case 'frac':
        final c = '\\frac{${buf['p1']}}{${buf['p2']}}';
        res = '\\mathchoice{\\textstyle$c}{$c}{$c}{$c}';
        break;
      case 'pu-frac':
        final d = '\\frac{${_goInner(buf['p1'])}}{${_goInner(buf['p2'])}}';
        res = '\\mathchoice{\\textstyle$d}{$d}{$d}{$d}';
        break;
      case 'tex-math':
        res = '${buf['p1']} ';
        break;
      case 'frac-ce':
        res =
            '\\frac{${_goInner(buf['p1'])}}{${_goInner(buf['p2'])}}';
        break;
      case 'overset':
        res =
            '\\overset{${_goInner(buf['p1'])}}{${_goInner(buf['p2'])}}';
        break;
      case 'underset':
        res =
            '\\underset{${_goInner(buf['p1'])}}{${_goInner(buf['p2'])}}';
        break;
      case 'underbrace':
        res =
            '\\underbrace{${_goInner(buf['p1'])}}_{${_goInner(buf['p2'])}}';
        break;
      case 'color':
        res =
            '{\\color{${buf['color1']}}{${_goInner(buf['color2'])}}}';
        break;
      case 'color0':
        res = '\\color{${buf['color']}}';
        break;
      case 'arrow':
        final rd = _goInner(buf['rd']);
        final rq = _goInner(buf['rq']);
        String arrow = _getArrow(buf['r'] as String);
        if (rd.isNotEmpty || rq.isNotEmpty) {
          if (buf['r'] == '<=>' ||
              buf['r'] == '<=>>' ||
              buf['r'] == '<<=' + '>' ||
              buf['r'] == '<-->') {
            arrow = '\\long$arrow';
            if (rd.isNotEmpty) {
              arrow = '\\overset{$rd}{$arrow}';
            }
            if (rq.isNotEmpty) {
              if (buf['r'] == '<-->') {
                arrow = '\\underset{\\lower2mu{$rq}}{$arrow}';
              } else {
                arrow = '\\underset{\\lower6mu{$rq}}{$arrow}';
              }
            }
            arrow = ' {}\\mathrel{$arrow}{} ';
          } else {
            if (rq.isNotEmpty) {
              arrow += '[{$rq}]';
            }
            arrow += '{$rd}';
            arrow = ' {}\\mathrel{\\x$arrow}{} ';
          }
        } else {
          arrow = ' {}\\mathrel{\\long$arrow}{} ';
        }
        res = arrow;
        break;
      case 'operator':
        res = _getOperator(buf['kind_'] as String);
        break;
      case '1st-level escape':
        res = '${buf['p1']} ';
        break;
      case 'space':
        res = ' ';
        break;
      case 'tinySkip':
        res = '\\mkern2mu';
        break;
      case 'entitySkip':
        res = '~';
        break;
      case 'pu-space-1':
        res = '~';
        break;
      case 'pu-space-2':
        res = '\\mkern3mu ';
        break;
      case '1000 separator':
        res = '\\mkern2mu ';
        break;
      case 'commaDecimal':
        res = '{,}';
        break;
      case 'comma enumeration L':
        res = '{${buf['p1']}}\\mkern6mu ';
        break;
      case 'comma enumeration M':
        res = '{${buf['p1']}}\\mkern3mu ';
        break;
      case 'comma enumeration S':
        res = '{${buf['p1']}}\\mkern1mu ';
        break;
      case 'hyphen':
        res = '\\text{-}';
        break;
      case 'addition compound':
        res = '\\,{\\cdot}\\,';
        break;
      case 'electron dot':
        res = '\\mkern1mu \\bullet\\mkern1mu ';
        break;
      case 'KV x':
        res = '{\\times}';
        break;
      case 'prime':
        res = '\\prime ';
        break;
      case 'cdot':
        res = '\\cdot ';
        break;
      case 'tight cdot':
        res = '\\mkern1mu{\\cdot}\\mkern1mu ';
        break;
      case 'times':
        res = '\\times ';
        break;
      case 'circa':
        res = '{\\sim}';
        break;
      case '^':
        res = 'uparrow';
        break;
      case 'v':
        res = 'downarrow';
        break;
      case 'ellipsis':
        res = '\\ldots ';
        break;
      case '/':
        res = '/';
        break;
      case ' / ':
        res = '\\,/\\,';
        break;
      default:
        throw MhchemError('MhchemBugT', 'mhchem bug T. Please report.');
    }
    return res;
  }

  static String _getArrow(String a) {
    switch (a) {
      case '->':
        return 'rightarrow';
      case '\u2192':
        return 'rightarrow';
      case '\u27F6':
        return 'rightarrow';
      case '<-':
        return 'leftarrow';
      case '<->':
        return 'leftrightarrow';
      case '<-->':
        return 'leftrightarrows';
      case '<=>':
        return 'rightleftharpoons';
      case '\u21CC':
        return 'rightleftharpoons';
      case '<=>>':
        return 'Rightleftharpoons';
      case '<<=>':
        return 'Leftrightharpoons';
      default:
        throw MhchemError('MhchemBugT', 'mhchem bug T. Please report.');
    }
  }

  static String _getBond(String a) {
    switch (a) {
      case '-':
        return '{-}';
      case '1':
        return '{-}';
      case '=':
        return '{=}';
      case '2':
        return '{=}';
      case '#':
        return '{\\equiv}';
      case '3':
        return '{\\equiv}';
      case '~':
        return '{\\tripledash}';
      case '~-':
        return '{\\rlap{\\lower.1em{-}}\\raise.1em{\\tripledash}}';
      case '~=':
        return '{\\rlap{\\lower.2em{-}}\\rlap{\\raise.2em{\\tripledash}}-}';
      case '~--':
        return '{\\rlap{\\lower.2em{-}}\\rlap{\\raise.2em{\\tripledash}}-}';
      case '-~-':
        return '{\\rlap{\\lower.2em{-}}\\rlap{\\raise.2em{-}}\\tripledash}';
      case '...':
        return '{{\\cdot}{\\cdot}{\\cdot}}';
      case '....':
        return '{{\\cdot}{\\cdot}{\\cdot}{\\cdot}}';
      case '->':
        return '{\\rightarrow}';
      case '<-':
        return '{\\leftarrow}';
      case '<':
        return '{<}';
      case '>':
        return '{>}';
      default:
        throw MhchemError('MhchemBugT', 'mhchem bug T. Please report.');
    }
  }

  static String _getOperator(String a) {
    switch (a) {
      case '+':
        return ' {}+{} ';
      case '-':
        return ' {}-{} ';
      case '=':
        return ' {}={} ';
      case '<':
        return ' {}<{} ';
      case '>':
        return ' {}>{} ';
      case '<<':
        return ' {}\\ll{} ';
      case '>>':
        return ' {}\\gg{} ';
      case '\\pm':
        return ' {}\\pm{} ';
      case '\\approx':
        return ' {}\\approx{} ';
      case r'$\approx$':
        return ' {}\\approx{} ';
      case 'v':
        return ' \\downarrow{} ';
      case '(v)':
        return ' \\downarrow{} ';
      case '^':
        return ' \\uparrow{} ';
      case '(^)':
        return ' \\uparrow{} ';
      default:
        throw MhchemError('MhchemBugT', 'mhchem bug T. Please report.');
    }
  }
}
