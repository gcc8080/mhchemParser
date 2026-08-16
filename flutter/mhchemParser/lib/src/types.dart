class MhchemError implements Exception {
  final String code;
  final String message;
  MhchemError(this.code, this.message);

  @override
  String toString() => 'MhchemError($code): $message';
}

class MatchResult {
  final Object match_;
  final String remainder;
  MatchResult(this.match_, this.remainder);
}

class Buffer {
  String? a;
  String? b;
  String? p;
  String? o;
  String? q;
  String? d;
  String? dType;

  String? r;
  String? rdt;
  String? rd;
  String? rqt;
  String? rq;

  String? text_;
  String? rm;

  int parenthesisLevel = 0;
  bool sb = false;
  bool beginsWithBond = false;

  void clear() {
    a = b = p = o = q = d = dType = null;
    r = rdt = rd = rqt = rq = null;
    text_ = rm = null;
    sb = false;
  }

  void clearAll() {
    a = b = p = o = q = d = dType = null;
    r = rdt = rd = rqt = rq = null;
    text_ = rm = null;
    parenthesisLevel = 0;
    sb = false;
    beginsWithBond = false;
  }
}

class Transition {
  final String pattern;
  final Task task;
  Transition(this.pattern, this.task);
}

class Task {
  final List<ActionEntry> action_;
  final String? nextState;
  final bool revisit;
  final bool toContinue;
  Task(this.action_,
      {this.nextState, this.revisit = false, this.toContinue = false});
}

class ActionEntry {
  final String type_;
  final dynamic option;
  ActionEntry(this.type_, [this.option]);
}

typedef ActionFn = Object? Function(Buffer buffer, dynamic m, dynamic option);

class StateMachine {
  final Map<String, List<Transition>> transitions;
  final Map<String, ActionFn> actions;
  StateMachine(this.transitions, this.actions);
}
