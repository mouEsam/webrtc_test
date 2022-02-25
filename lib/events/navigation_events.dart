import 'package:flutter/cupertino.dart';

import 'event.dart';

abstract class NavigationEvent extends AppEvent {
  const NavigationEvent();
}

class BeginNavigationEvent extends NavigationEvent {
  const BeginNavigationEvent();
}

class AuthRequiredNavigationEvent extends NavigationEvent {
  final ValueChanged<bool>? onResult;
  const AuthRequiredNavigationEvent(this.onResult);
}

class ReAuthRequiredNavigationEvent extends AuthRequiredNavigationEvent {
  const ReAuthRequiredNavigationEvent(ValueChanged<bool>? onResult)
      : super(onResult);
}
