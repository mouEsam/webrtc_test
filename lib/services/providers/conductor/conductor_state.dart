part of 'route_conductor.dart';

class StatesComplex {
  final UserState userState;
  const StatesComplex(this.userState);
}

abstract class ConductorState {
  final bool auth;
  final Completer<void> _completer = Completer();
  bool get isHandled => _completer.isCompleted;
  Future<void> get awaitHandle => _completer.future;
  ConductorState(this.auth, [complete]) {
    if (complete != null) {
      _complete(complete);
    }
  }

  void _complete([_ = 0]) {
    if (!_completer.isCompleted) {
      _completer.complete(_);
    }
  }
}

class InitialConductorState extends ConductorState {
  InitialConductorState() : super(false, 0);
}

class AuthRequiredConductorState extends ConductorState {
  AuthRequiredConductorState([complete]) : super(false, complete);
}

class LoadingConductorState extends ConductorState {
  LoadingConductorState([complete]) : super(false, complete);
}

class MainConductorState extends ConductorState {
  MainConductorState([complete]) : super(true, complete);
}
