import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/data/remote/apis/room_client.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';
import 'package:webrtc_test/providers/room/room_states.dart';

final roomNotifierProvider =
    StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(ref.read(roomClientProvider));
});

class RoomNotifier extends StateNotifier<RoomState> {
  final IRoomClient _roomClient;

  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  RoomNotifier(
    this._roomClient,
  ) : super(const InitialRoomState());

  Future<void> createRoom(String roomName, String name) async {
    RTCPeerConnection? connection;
    return safeAttempt(() async {
      connection = await createPeerConnection(configuration);
      final offer = await connection!.createOffer();
      await connection!.setLocalDescription(offer);
      final data = await _roomClient.createRoom(name, roomName, offer);
      final user = data.second;
      final room = data.first;
      _setupStreamsAndListeners(connection!, room, user);
      return ConnectedRoomState(
        room: data.first,
        user: data.second,
        connection: connection!,
      );
    }, connection?.dispose);
  }

  Future<void> joinRoom(AvailableRoom availableRoom, String name) async {
    RTCPeerConnection? connection;
    return safeAttempt(() async {
      final offer = availableRoom.offer;
      connection = await createPeerConnection(configuration);
      await connection!.setRemoteDescription(offer);
      final answer = await connection!.createAnswer();
      await connection!.setLocalDescription(answer);
      final data = await _roomClient.answerRoom(availableRoom, name, answer);
      final user = data.second;
      final room = data.first;
      _setupStreamsAndListeners(connection!, room, user);
      return ConnectedRoomState(
        room: data.first,
        user: data.second,
        connection: connection!,
      );
    }, connection?.dispose);
  }

  void _setupStreamsAndListeners(
    RTCPeerConnection connection,
    Room room,
    Attendee user,
  ) {
    _setupRoomListeners(room, user, connection);
    _registerPeerConnectionListeners(connection, (candidate) {
      _roomClient.addCandidate(user, candidate);
    });
  }

  void _setupRoomListeners(
      Room room, Attendee user, RTCPeerConnection connection) {
    log("_setupRoomListeners");
    room.attendees.addDiffListener(onAdded: (newAttendee) {
      log("_setupRoomListeners ${newAttendee.id}");
      if (user.id != newAttendee.id) {
        connection.setRemoteDescription(newAttendee.sessionDescription);
      }
      newAttendee.candidates.addDiffListener(onAdded: (newCandidate) {
        connection.addCandidate(newCandidate.iceCandidate);
      });
    }, onRemoved: (attendee) {
      attendee.candidates.dispose();
    });
  }

  Future<void> exitRoom() async {
    final state = this.state;
    if (state is ConnectedRoomState) {
      return safeAttempt(() async {
        final attendee = state.user;
        state.room.attendees.forEach((value) {
          value.candidates.dispose();
        });
        state.room.attendees.dispose();
        await _roomClient.exitRoom(attendee);
        if (state.room.attendees.isEmpty) {
          await _roomClient.closeRoom(state.room);
        }
        state.connection.close();
        return const NoRoomState();
      });
    }
  }

  Future<void> safeAttempt(FutureOr<RoomState> Function() action,
      [VoidCallback? disposer]) {
    final completer = Completer();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      completer.complete(Future(() async {
        state = const LoadingRoomState();
        try {
          state = await action();
        } catch (e, s) {
          log(e.toString());
          log(s.toString());
          state = const InitialRoomState();
          disposer?.call();
        }
      }));
    });
    return completer.future;
  }

  void _registerPeerConnectionListeners(
    RTCPeerConnection connection,
    ValueChanged<RtcIceCandidateModel> onCandidate,
  ) {
    connection.onIceCandidate = (RTCIceCandidate candidate) {
      log('Got candidate: ${candidate.toMap()}');
      onCandidate(RtcIceCandidateModel.fromCandidate(candidate));
    };
    connection.onIceGatheringState = (RTCIceGatheringState state) {
      log('ICE gathering state changed: $state');
    };
    connection.onConnectionState = (RTCPeerConnectionState state) {
      log('Connection state change: $state');
    };
    connection.onSignalingState = (RTCSignalingState state) {
      log('Signaling state change: $state');
    };
  }
}
