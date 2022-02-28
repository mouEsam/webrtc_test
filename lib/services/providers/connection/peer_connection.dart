import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';

class EstablishedPeerConnection {
  final RTCPeerConnection connection;
  final ListDiffNotifier<RtcIceCandidateModel> _localCandidates;
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
  bool _localSat = false;
  bool _remoteSat = false;

  EstablishedPeerConnection._(this.connection, this._localCandidates) {
    _registerCallbacks();
  }

  static Future<EstablishedPeerConnection> establish(
      Map<String, dynamic> configuration,
      ListDiffNotifier<RtcIceCandidateModel> candidates,
      [MediaStream? localStream]) async {
    final connection = await createPeerConnection(configuration);
    final established = EstablishedPeerConnection._(connection, candidates);
    established.localStream = localStream;
    return established;
  }

  set localStream(MediaStream? localStream) {
    if (localStream?.id != _localStream?.id) {
      if (localStream != null) {
        _registerStreamCallbacks(localStream);
      }
      if (_localStream != null) {
        _unregisterStreamCallbacks(_localStream!);
      }
    }
    _localStream = localStream;
  }

  void dispose() {
    if (_localStream != null) {
      _unregisterStreamCallbacks(_localStream!);
    }
    remoteStreams.dispose();
    connection.close();
  }

  void _registerCallbacks() {
    connection.onIceCandidate = (candidate) {
      log('Got candidate: ${candidate.toMap()}');
      _localCandidates.addItem(RtcIceCandidateModel.fromCandidate(candidate));
    };
  }

  void _registerStreamCallbacks(MediaStream localStream) {
    localStream.getTracks().forEach((track) {
      connection.addTrack(track, localStream);
    });
    connection.onAddTrack = (stream, track) {
      log("Add remote stream track");
      remoteStreams[stream.id] ??= stream;
      remoteStreams[stream.id]?.addTrack(track);
    };
    connection.onRemoveTrack = (stream, track) {
      log("Remove remote stream track");
      remoteStreams[stream.id] ??= stream;
      remoteStreams[stream.id]?.removeTrack(track);
    };
    connection.onAddStream = (stream) {
      log("Add remote stream");
      remoteStreams[stream.id] = stream;
    };
    connection.onRemoveStream = (stream) {
      log("Remove remote stream");
      remoteStreams.removeItem(stream.id);
    };
  }

  void _unregisterStreamCallbacks(MediaStream localStream) {
    connection.removeStream(localStream);
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await connection.createOffer();
    _setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final offer = await connection.createAnswer();
    _setLocalDescription(offer);
    return offer;
  }

  Future<void> _setLocalDescription(RTCSessionDescription offer) {
    _localSat = true;
    return connection.setLocalDescription(offer);
  }

  Future<void> _setRemoteDescription(RTCSessionDescription offer) {
    _remoteSat = true;
    return connection.setRemoteDescription(offer);
  }
}

class PeerConnection extends ChangeNotifier {
  final EstablishedPeerConnection _connection;
  final String id;
  final Attendee remote;
  final ListDiffNotifier<RtcIceCandidateModel> _remoteCandidates;

  bool get localSat => _connection._localSat;
  bool get remoteSat => _connection._remoteSat;
  RTCPeerConnection get connection => _connection.connection;
  MapDiffNotifier<String, MediaStream> get remoteStreams =>
      _connection.remoteStreams;

  PeerConnection._(
    this.id,
    this._connection,
    this.remote,
    this._remoteCandidates,
  ) {
    _registerCallbacks();
  }

  set localStream(MediaStream? localStream) {
    _connection.localStream = localStream;
  }

  static Future<PeerConnection> createConnection(
    String id,
    Attendee remote,
    ListDiffNotifier<RtcIceCandidateModel> remoteCandidates,
    EstablishedPeerConnection connection,
  ) async {
    final _connection = PeerConnection._(
      id,
      connection,
      remote,
      remoteCandidates,
    );
    return _connection;
  }

  Future<RTCSessionDescription> setOffer(
      {RTCSessionDescription? offer, bool remote = false}) async {
    offer ??= await _connection.createOffer();
    if (remote) {
      await _connection._setRemoteDescription(offer);
    }
    return offer;
  }

  Future<RTCSessionDescription> setAnswer(
      {RTCSessionDescription? answer, bool remote = false}) async {
    answer ??= await _connection.createAnswer();
    if (remote) {
      await _connection._setRemoteDescription(answer);
    }
    return answer;
  }

  @override
  void dispose() {
    super.dispose();
    _remoteCandidates.dispose();
  }

  void _registerCallbacks() {
    _remoteCandidates.addDiffListener(onAdded: (candidate) {
      connection.addCandidate(candidate.iceCandidate);
    });
  }
}
