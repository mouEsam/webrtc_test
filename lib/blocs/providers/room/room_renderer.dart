import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/providers/room/room_notifier.dart';
import 'package:webrtc_test/blocs/providers/room/room_states.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';
import 'package:webrtc_test/services/providers/connection/peer_connection.dart';

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
  RTCVideoRenderer? localRenderer;

  RoomRenderer(
    this._roomNotifier,
  );

  void init() {
    localRenderer = RTCVideoRenderer();
    localRenderer?.initialize();
  }

  void dispose() {
    _roomNotifier.connections.removeDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
    _roomNotifier.localStream.removeListener(_localStreamListener);
    localRenderer?.dispose();
    localRenderer = null;
    remoteRenderers.dispose();
  }

  void setupRoom() {
    _roomNotifier.connections.addDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
    _roomNotifier.localStream.addListener(_localStreamListener);
  }

  void _localStreamListener() {
    localRenderer?.srcObject = _roomNotifier.localStream.value;
  }

  void clear() {
    _roomNotifier.connections.removeDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
    if (localRenderer != null && localRenderer?.srcObject != null) {
      localRenderer?.srcObject = null;
    }
    for (var renderer in remoteRenderers.values) {
      renderer.srcObject = null;
      renderer.dispose();
    }
    remoteRenderers.clear();
  }

  void _onConnectionRemoved(PeerConnection connection) {
    final renderer = remoteRenderers.removeItem(connection.remote.id);
    if (renderer?.srcObject != null) {
      renderer?.srcObject = null;
    }
    renderer?.dispose();
  }

  void _onConnectionAdded(PeerConnection connection) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    connection.remoteStreams.addListener(() {
      log("different streams event");
      final streams = connection.remoteStreams.items.values.toList();
      if (streams.isNotEmpty) {
        renderer.srcObject = streams.first;
      } else if (renderer.srcObject != null) {
        renderer.srcObject = null;
      }
      remoteRenderers[connection.remote.id] = renderer;
    });
    remoteRenderers[connection.remote.id] = renderer;
  }
}
