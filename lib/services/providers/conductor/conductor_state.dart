part of 'route_conductor.dart';

abstract class ConductorState {
  final bool auth;
  final Completer<void> _completer = Completer();
  bool get isHandled => _completer.isCompleted;
  Future<void> get awaitHandle => _completer.future;
  ConductorState(this.auth, [complete]) {
    if (complete != null) {
      _completer.complete(complete);
    }
  }

  void _complete(_) {
    if (!_completer.isCompleted) {
      _completer.complete(_);
    }
  }
}

class InitialConductorState extends ConductorState {
  InitialConductorState() : super(false, 0);
}

class AuthRequiredConductorState extends ConductorState {
  AuthRequiredConductorState() : super(false);
}

class LoadingConductorState extends ConductorState {
  LoadingConductorState() : super(false);
}

class MainConductorState extends ConductorState {
  MainConductorState() : super(true);
}
