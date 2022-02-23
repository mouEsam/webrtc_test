import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/data/remote/apis/room_client.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';

import 'room_states.dart';

final roomsNotifierProvider =
    StateNotifierProvider<RoomsNotifier, RoomsState>((ref) {
  return RoomsNotifier(
    ref.read(roomClientProvider),
  );
});

class RoomsNotifier extends StateNotifier<RoomsState> {
  final IRoomClient _roomClient;

  RoomsNotifier(
    this._roomClient,
  ) : super(const InitialRoomsState());

  Future<void> loadRooms() {
    return safeAttempt(() async {
      final rooms = await _roomClient.getAvailableRooms();
      return LoadedRoomsState(rooms: rooms);
    });
  }

  Future<void> safeAttempt(FutureOr<RoomsState> Function() action) async {
    state = const LoadingRoomsState();
    try {
      state = await action();
    } catch (e) {
      state = const InitialRoomsState();
    }
  }
}
