import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/services/providers/connection/peer_connection.dart';

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
  final List<PeerConnection> connections;
  const ConnectedRoomState({
    required this.room,
    required this.user,
    required this.connections,
  });
}

class NoRoomState extends RoomState {
  const NoRoomState();
}
