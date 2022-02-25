import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';

class PeerConnection extends ChangeNotifier {
  final RTCPeerConnection connection;
  final Attendee _local; // user
  final Attendee remote; // other side
  MediaStream? _localStream;
  final MapDiffNotifier<String, MediaStream> remoteStreams =
      MapDiffNotifier((streams) {
    for (final stream in streams.values) {
      stream.getTracks().forEach((track) {
        track.stop();
      });
      stream.dispose();
    }
  });

  PeerConnection._(this.connection, this._local, this.remote) {
    _registerCallbacks();
  }

  set localStream(MediaStream? localStream) {
    if (localStream != null) {
      _registerStreamCallbacks(localStream);
    } else if (_localStream != null) {
      _unregisterStreamCallbacks(_localStream!);
    }
    _localStream = localStream;
  }

  // static Future<PeerConnection> createConnection(
  //   bool isHost,
  //   Attendee host,
  //   Attendee guest,
  //   RTCPeerConnection connection,
  // ) async {
  //   final local = isHost ? host : guest;
  //   final remote = isHost ? guest : host;
  //   await connection.setLocalDescription(isHost ? host.offer : guest.answer);
  //   await connection.setRemoteDescription(isHost ? guest.answer : host.offer);
  //   final _connection = PeerConnection._(connection, local, remote);
  //   _connection._remoteStream = await createLocalMediaStream(remote.id);
  //   return _connection;
  // }

  static Future<PeerConnection> createConnection(
    Attendee local,
    Attendee remote,
    RTCPeerConnection connection,
  ) async {
    final _connection = PeerConnection._(connection, local, remote);
    return _connection;
  }

  Future<RTCSessionDescription> setOffer([RTCSessionDescription? offer]) async {
    final remote = offer != null;
    offer ??= await connection.createOffer();
    if (remote) {
      connection.setRemoteDescription(offer);
    } else {
      connection.setLocalDescription(offer);
    }
    return offer;
  }

  Future<RTCSessionDescription> setAnswer(
      [RTCSessionDescription? answer]) async {
    final local = answer == null;
    answer ??= await connection.createAnswer();
    if (local) {
      connection.setLocalDescription(answer);
    } else {
      connection.setRemoteDescription(answer);
    }
    return answer;
  }

  @override
  void dispose() {
    super.dispose();
    remote.candidates.dispose();
    remoteStreams.dispose();
    connection.close();
  }

  void _registerCallbacks() {
    remote.candidates.addDiffListener(onAdded: (candidate) {
      connection.addCandidate(candidate.iceCandidate);
    });
    connection.onIceCandidate = (candidate) {
      log('Got candidate: ${candidate.toMap()}');
      _local.candidates.addItem(RtcIceCandidateModel.fromCandidate(candidate));
    };
    connection.onAddTrack = (stream, track) {
      remoteStreams[stream.id]?.addTrack(track);
    };
    connection.onRemoveTrack = (stream, track) {
      remoteStreams[stream.id]?.removeTrack(track);
    };
    connection.onAddStream = (stream) {
      log("Add remote stream");
      remoteStreams[stream.id] = stream;
    };
    connection.onRemoveStream = (stream) {
      log("Add remote stream");
      remoteStreams.removeItem(stream.id);
    };
  }

  void _registerStreamCallbacks(MediaStream localStream) {
    localStream.getTracks().forEach((track) {
      connection.addTrack(track, localStream);
    });
  }

  void _unregisterStreamCallbacks(MediaStream localStream) {
    connection.removeStream(localStream);
  }
}
