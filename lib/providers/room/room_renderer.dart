import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';
import 'package:webrtc_test/providers/room/room_notifier.dart';
import 'package:webrtc_test/providers/room/room_states.dart';

final roomRendererProvider = StateProvider.autoDispose((ref) {
  final renderer = RoomRenderer(
    ref.read(roomNotifierProvider.notifier),
  );
  renderer.init();
  ref.onDispose(() {
    renderer.dispose();
  });
  ref.listen<RoomState>(roomNotifierProvider, (previous, next) {
    if (next is ConnectedRoomState) {
      renderer.setupRoom();
    } else if (next is NoRoomState) {
      renderer.clear();
    }
  }, fireImmediately: true);
  return renderer;
});

class RoomRenderer {
  final RoomNotifier _roomNotifier;
  final MapDiffNotifier<String, RTCVideoRenderer> remoteRenderers =
      MapDiffNotifier((renderers) {
    for (var renderer in renderers.values) {
      renderer.srcObject = null;
      renderer.dispose();
    }
  });
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  RoomRenderer(
    this._roomNotifier,
  );

  void init() {
    localRenderer.initialize();
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderers.dispose();
    _roomNotifier.connections.forEach((value) {
      value.localStream = null;
    });
  }

  void setupRoom() {
    _roomNotifier.connections.addDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
  }

  void clear() {
    _roomNotifier.connections.removeDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
    localRenderer.srcObject = null;
    for (var renderer in remoteRenderers.values) {
      renderer.srcObject = null;
    }
    _roomNotifier.connections.forEach((value) {
      value.localStream = null;
    });
  }

  void _onConnectionRemoved(connection) {
    final renderer = remoteRenderers.removeItem(connection.remote.id);
    renderer?.dispose();
    connection.localStream = null;
  }

  void _onConnectionAdded(connection) async {
    connection.localStream = localRenderer.srcObject;
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    connection.remoteStreams.addListener(() {
      final streams = connection.remoteStreams.items.values.toList();
      if (streams.isNotEmpty) {
        renderer.srcObject = streams.first;
      } else {
        renderer.srcObject = null;
      }
    });
    remoteRenderers[connection.remote.id] = renderer;
  }

  Future<void> openUserMedia() async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': false});
    _roomNotifier.connections.forEach((value) {
      value.localStream = stream;
    });
    localRenderer.srcObject = stream;
  }
}
