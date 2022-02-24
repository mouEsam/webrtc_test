import 'package:webrtc_test/blocs/models/user.dart';

abstract class IAuthClient {
  Stream<UserAccount?> get currentUser;

  Future<void> signup(String name, String email, String password);

  Future<void> login(String email, String password);

  Future<void> anonymousLogin(String name);
}
