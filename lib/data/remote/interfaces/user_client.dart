import 'package:webrtc_test/blocs/models/available_user.dart';

abstract class IUserClient {
  Future<List<AvailableUser>> getAvailableUsers();
}
