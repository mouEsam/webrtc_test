import 'package:webrtc_test/blocs/models/available_room.dart';

abstract class RoomsState {
  const RoomsState();
}

class InitialRoomsState extends RoomsState {
  const InitialRoomsState();
}

class LoadingRoomsState extends RoomsState {
  const LoadingRoomsState();
}

class LoadedRoomsState extends RoomsState {
  final List<AvailableRoom> rooms;
  const LoadedRoomsState({required this.rooms});
}
