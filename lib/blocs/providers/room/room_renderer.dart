import 'dart:async';
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
  final Completer<bool> _rendererCompleter = Completer();

  RoomRenderer(
    this._roomNotifier,
  );

  void init() {
    localRenderer = RTCVideoRenderer()
      ..initialize().then((value) {
        log("initialized true");
        _rendererCompleter.complete(true);
      }).onError((error, stackTrace) {
        log("initialized false");
        _rendererCompleter.complete(false);
      });
  }

  void dispose() {
    clear();
    localRenderer?.dispose();
    localRenderer = null;
    remoteRenderers.dispose();
    if (!_rendererCompleter.isCompleted) {
      _rendererCompleter.complete(false);
    }
  }

  void clear() {
    _roomNotifier.connections.removeDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
    _roomNotifier.localStream.removeListener(_localStreamListener);
    if (localRenderer?.srcObject != null) {
      localRenderer?.srcObject = null;
    }
    for (var renderer in remoteRenderers.values) {
      renderer.srcObject = null;
      renderer.dispose();
    }
    remoteRenderers.clear();
  }

  void setupRoom() {
    _roomNotifier.connections.addDiffListener(
      onAdded: _onConnectionAdded,
      onRemoved: _onConnectionRemoved,
    );
    log("added listener");
    final ls = _roomNotifier.localStream;
    if (ls.value != null) {
      _localStreamListener(ls.value);
    }
    _roomNotifier.localStream.addListener(_localStreamListener);
  }

  Future<void> _localStreamListener([MediaStream? stream]) async {
    stream ??= _roomNotifier.localStream.value;
    log("got renderer to stream");
    if (await _rendererCompleter.future) {
      log("got renderer future");
      if (stream != null && stream.id != localRenderer?.srcObject?.id) {
        localRenderer?.srcObject = stream;
      }
    }
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
