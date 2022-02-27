import 'package:webrtc_test/blocs/models/user.dart';

abstract class UserState {
  const UserState();
}

class LoadingUserState extends UserState {
  const LoadingUserState();
}

abstract class AuthenticatedUserState extends UserState {
  final UserAccount userAccount;
  const AuthenticatedUserState(this.userAccount);
}

class LoggedInUserState extends AuthenticatedUserState {
  const LoggedInUserState(UserAccount userAccount) : super(userAccount);
}

class ReAuthenticatedUserState extends AuthenticatedUserState {
  const ReAuthenticatedUserState(UserAccount userAccount) : super(userAccount);
}

abstract class UnAuthenticatedUserState extends UserState {
  const UnAuthenticatedUserState();
}

class ExpiredUserState extends UnAuthenticatedUserState {
  final UserAccount userAccount;
  const ExpiredUserState(this.userAccount);
}

class LoggedOutUserState extends UnAuthenticatedUserState {
  const LoggedOutUserState();
}

class InitialUnAuthenticatedUserState extends UnAuthenticatedUserState {
  const InitialUnAuthenticatedUserState();
}
