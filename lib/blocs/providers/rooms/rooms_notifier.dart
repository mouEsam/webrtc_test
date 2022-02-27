import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/data/remote/apis/room_client.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';
import 'package:webrtc_test/exceptions/page_error.dart';
import 'package:webrtc_test/exceptions/page_error_handler.dart';
import 'package:webrtc_test/helpers/providers/page_notifier.dart';
import 'package:webrtc_test/helpers/providers/page_state.dart';

final roomsNotifierProvider =
    StateNotifierProvider<RoomsNotifier, PageState>((ref) {
  return RoomsNotifier(
    ref.read(roomClientProvider),
    ref.read(pageErrorHandlerProvider),
  );
});

class RoomsNotifier extends PageNotifier {
  final IRoomClient _roomClient;

  RoomsNotifier(
    this._roomClient,
    PageErrorHandler errorHandler,
  ) : super(errorHandler) {
    loadRooms();
  }

  Future<void> loadRooms() {
    return safeAttempt(() async {
      final rooms = await _roomClient.getAvailableRooms();
      return LoadedPageState(rooms);
    }, errorFactory: (error) {
      return OperationPageError.retry(error, loadRooms);
    });
  }
}
