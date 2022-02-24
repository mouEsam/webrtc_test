import 'package:webrtc_test/blocs/models/user.dart';

abstract class UserState {
  const UserState();
}

class LoadingUserState extends UserState {
  const LoadingUserState();
}

class AuthenticatedUserState extends UserState {
  final UserAccount userAccount;
  const AuthenticatedUserState(this.userAccount);
}

class UnAuthenticatedUserState extends UserState {
  const UnAuthenticatedUserState();
}
