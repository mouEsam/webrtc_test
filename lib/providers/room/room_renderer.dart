import 'dart:async';
import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/providers/room/room_notifier.dart';
import 'package:webrtc_test/providers/room/room_states.dart';

final roomRendererProvider = StateProvider.autoDispose((ref) {
  final renderer = RoomRenderer(
    ref.read(roomNotifierProvider.notifier),
    RTCVideoRenderer(),
    RTCVideoRenderer(),
  );
  renderer.init();
  ref.onDispose(() {
    renderer.dispose();
  });
  ref.listen<RoomState>(roomNotifierProvider, (previous, next) {
    if (next is ConnectedRoomState) {
      renderer.setupRoom(next);
    } else {
      renderer.clear();
    }
  });
  return renderer;
});

class RoomRenderer {
  final RoomNotifier _roomNotifier;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;

  RoomRenderer(
    this._roomNotifier,
    this.localRenderer,
    this.remoteRenderer,
  );

  void init() {
    localRenderer.initialize();
    remoteRenderer.initialize();
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
  }

  void clear() {
    final stream = localRenderer.srcObject;
    localRenderer.srcObject = null;
    if (stream != null) {
      for (var track in stream.getTracks()) {
        track.stop();
      }
      stream.dispose();
    }
    remoteRenderer.srcObject?.dispose();
    remoteRenderer.srcObject = null;
  }

  Future<void> openUserMedia() async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': false});
    final state = _roomNotifier.state;
    if (state is ConnectedRoomState) {
      _setupTracks(stream, state.connection);
    }
    localRenderer.srcObject = stream;
  }

  void setupRoom(ConnectedRoomState connectedRoomState) {
    _setupStreamsAndListeners(
      connectedRoomState.connection,
      connectedRoomState.room,
      connectedRoomState.user,
    );
  }

  void _setupStreamsAndListeners(
    RTCPeerConnection connection,
    Room room,
    Attendee user,
  ) {
    if (localRenderer.srcObject != null) {
      _setupTracks(localRenderer.srcObject!, connection);
    }
    _registerPeerConnectionListeners(connection);
  }

  void _setupTracks(MediaStream stream, RTCPeerConnection peerConnection) {
    stream.getTracks().forEach((track) {
      peerConnection.addTrack(track, stream);
    });
  }

  void _registerPeerConnectionListeners(RTCPeerConnection connection) {
    connection.onTrack = (RTCTrackEvent event) {
      log('Got remote track: ${event.streams[0]}');
      event.streams[0].getTracks().forEach((track) {
        log('Add a track to the remoteStream $track');
        remoteRenderer.srcObject?.addTrack(track);
      });
    };
    connection.onAddStream = (MediaStream stream) {
      log("Add remote stream");
      remoteRenderer.srcObject = stream;
    };
  }
}
