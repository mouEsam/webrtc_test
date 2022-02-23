import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/room.dart';

abstract class RoomState {
  const RoomState();
}

class InitialRoomState extends RoomState {
  const InitialRoomState();
}

class LoadingRoomState extends RoomState {
  const LoadingRoomState();
}

class ConnectedRoomState extends RoomState {
  final Room room;
  final Attendee user;
  final RTCPeerConnection connection;
  const ConnectedRoomState(
      {required this.room, required this.user, required this.connection});
}

class NoRoomState extends RoomState {
  const NoRoomState();
}
