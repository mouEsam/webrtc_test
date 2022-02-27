import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';

class PeerConnection extends ChangeNotifier {
  final RTCPeerConnection connection;
  final String id;
  final Attendee remote;
  final ListDiffNotifier<RtcIceCandidateModel> _localCandidates;
  final ListDiffNotifier<RtcIceCandidateModel> _remoteCandidates;
  final MapDiffNotifier<String, MediaStream> remoteStreams =
      MapDiffNotifier((streams) {
    for (final stream in streams.values) {
      stream.getTracks().forEach((track) {
        track.stop();
      });
      stream.dispose();
    }
  });
  MediaStream? _localStream;

  PeerConnection._(
    this.id,
    this.connection,
    this.remote,
    this._localCandidates,
    this._remoteCandidates,
  ) {
    _registerCallbacks();
  }

  set localStream(MediaStream? localStream) {
    if (localStream?.id != _localStream?.id) {
      if (localStream != null) {
        _registerStreamCallbacks(localStream);
      } else if (_localStream != null) {
        _unregisterStreamCallbacks(_localStream!);
      }
    }
    _localStream = localStream;
  }

  static Future<PeerConnection> createConnection(
    String id,
    Attendee remote,
    ListDiffNotifier<RtcIceCandidateModel> localCandidates,
    ListDiffNotifier<RtcIceCandidateModel> remoteCandidates,
    RTCPeerConnection connection,
  ) async {
    final _connection = PeerConnection._(
      id,
      connection,
      remote,
      localCandidates,
      remoteCandidates,
    );
    return _connection;
  }

  Future<RTCSessionDescription> setOffer(
      {RTCSessionDescription? offer, bool remote = false}) async {
    offer ??= await connection.createOffer();
    if (remote) {
      connection.setRemoteDescription(offer);
    } else {
      connection.setLocalDescription(offer);
    }
    return offer;
  }

  Future<RTCSessionDescription> setAnswer(
      {RTCSessionDescription? answer, bool remote = false}) async {
    answer ??= await connection.createAnswer();
    if (remote) {
      connection.setRemoteDescription(answer);
    } else {
      connection.setLocalDescription(answer);
    }
    return answer;
  }

  @override
  void dispose() {
    super.dispose();
    if (_localStream != null) {
      _unregisterStreamCallbacks(_localStream!);
    }
    _remoteCandidates.dispose();
    remoteStreams.dispose();
    connection.close();
  }

  void _registerCallbacks() {
    _remoteCandidates.addDiffListener(onAdded: (candidate) {
      connection.addCandidate(candidate.iceCandidate);
    });
    connection.onIceCandidate = (candidate) {
      log('Got candidate: ${candidate.toMap()}');
      _localCandidates.addItem(RtcIceCandidateModel.fromCandidate(candidate));
    };
    connection.onAddTrack = (stream, track) {
      remoteStreams[stream.id] ??= stream;
      remoteStreams[stream.id]?.addTrack(track);
    };
    connection.onRemoveTrack = (stream, track) {
      remoteStreams[stream.id] ??= stream;
      remoteStreams[stream.id]?.removeTrack(track);
    };
    // connection.onAddStream = (stream) {
    //   log("Add remote stream");
    //   remoteStreams[stream.id] = stream;
    // };
    connection.onRemoveStream = (stream) {
      log("Remove remote stream");
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
