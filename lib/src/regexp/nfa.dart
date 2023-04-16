/// Nondeterministic Finite Automaton
class Nfa {
  Nfa({required this.start, required this.end});

  final NfaState start;
  final NfaState end;

  bool match(String input) {
    var currentStates = <NfaState>{};
    _addStates(start, currentStates);
    for (final value in input.runes) {
      final nextStates = <NfaState>{};
      for (final state in currentStates) {
        final nextState = state.transitions[value];
        if (nextState != null) {
          _addStates(nextState, nextStates);
        }
      }
      if (nextStates.isEmpty) return false;
      currentStates = nextStates;
    }
    return currentStates.any((state) => state.isEnd);
  }

  void _addStates(NfaState state, Set<NfaState> states) {
    if (!states.add(state)) return;
    for (var other in state.epsilons) {
      _addStates(other, states);
    }
  }
}

class NfaState {
  NfaState({required this.isEnd});

  bool isEnd;

  final Map<int, NfaState> transitions = {};

  final List<NfaState> epsilons = [];
}
