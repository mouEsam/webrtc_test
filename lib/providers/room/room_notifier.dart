import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/blocs/models/user.dart';
import 'package:webrtc_test/data/remote/apis/room_client.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';
import 'package:webrtc_test/helpers/utils/box.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/providers/auth/user_notifier.dart';
import 'package:webrtc_test/providers/auth/user_state.dart';
import 'package:webrtc_test/providers/room/room_states.dart';
import 'package:webrtc_test/services/providers/connection/peer_connection.dart';

final roomNotifierProvider =
    StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(
    ref.read(roomClientProvider),
    ref.read(userProvider.notifier),
  );
});

class RoomNotifier extends StateNotifier<RoomState> {
  final UserNotifier _userAccount;
  final IRoomClient _roomClient;
  late UserAccount userAccount;
  ListDiffNotifier<RtcIceCandidateModel>? _candidates;
  final ListDiffNotifier<PeerConnection> connections =
      ListDiffNotifier((connections) {
    for (var connection in connections) {
      connection.dispose();
    }
  });

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
    this._userAccount,
  ) : super(const InitialRoomState()) {
    _userAccount.addListener((state) {
      if (state is AuthenticatedUserState) {
        userAccount = state.userAccount;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    connections.dispose();
    _candidates?.dispose();
  }

  Future<void> createRoom(String roomName, String name) async {
    return safeAttempt(() async {
      final data = await _roomClient.createRoom(name, userAccount);
      final user = data.second;
      final room = data.first;
      _candidates = _roomClient.getUserCandidates(
        room,
        userAccount,
        user,
      );
      _setupRoomListeners(
        room,
        user,
        _candidates!,
      );
      return ConnectedRoomState(
        room: data.first,
        user: data.second,
        connections: connections.items,
      );
    });
  }

  Future<void> joinRoom(AvailableRoom availableRoom, String name) async {
    RTCPeerConnection? connection;
    return safeAttempt(() async {
      connection = await createPeerConnection(configuration);
      final offer = await connection!.createOffer();
      final data = await _roomClient.joinRoom(
        availableRoom,
        userAccount,
        offer,
      );
      final user = data.second;
      final room = data.first;
      _candidates = _roomClient.getUserCandidates(
        room,
        userAccount,
        user,
      );
      _setupRoomListeners(
        room,
        user,
        _candidates!,
        offer,
        connection,
      );
      return ConnectedRoomState(
        room: data.first,
        user: data.second,
        connections: connections.items,
      );
    }, connection?.dispose);
  }

  void _setupRoomListeners(
    Room room,
    Attendee user,
    ListDiffNotifier<RtcIceCandidateModel> userCandidates, [
    RTCSessionDescription? offer,
    RTCPeerConnection? connection,
  ]) {
    final connectionBox = Box(connection);
    log("_setupRoomListeners");
    room.connections.addDiffListener(onAdded: (entry) async {
      final attendee = room.attendees.items.firstWhereOrNull((element) {
        return entry.key == element.id;
      });
      if (attendee == null) return;
      final existingConnection = connections.items.firstWhereOrNull((element) {
        return element.remote.id == entry.key;
      });
      final bool localAlreadySet = existingConnection != null;
      late final PeerConnection peerConnection;
      late final RTCPeerConnection connection;
      if (existingConnection != null) {
        peerConnection = existingConnection;
        connection = peerConnection.connection;
      } else {
        if (connectionBox.hasData) {
          connection = connectionBox.data;
          connectionBox.data = null;
        } else {
          connection = await createPeerConnection(configuration);
        }
        peerConnection = await PeerConnection.createConnection(
          user,
          attendee,
          userCandidates,
          _roomClient.getUserCandidates(
            room,
            userAccount,
            attendee,
          ),
          connection,
        );
        connections.addItem(peerConnection);
      }
      final connectionData = entry.value;
      if (connectionData.offerId == user.id) {
        if (!localAlreadySet) {
          await connection.setLocalDescription(offer ?? connectionData.offer);
        }
      } else {
        final remoteOffer = await connection.getRemoteDescription();
        if (remoteOffer == null) {
          await connection.setRemoteDescription(connectionData.offer);
        }
      }
      if (connectionData.answerId == user.id) {
        if (!localAlreadySet) {
          final answer = await connection.createAnswer();
          await connection.setLocalDescription(answer);
          final newConnection = connectionData.setAnswer(answer);
          room.connections[entry.key] = newConnection;
        }
      } else if (connectionData.answer != null) {
        final remoteAnswer = await connection.getRemoteDescription();
        if (remoteAnswer == null) {
          await connection.setRemoteDescription(connectionData.answer!);
        }
      }
    }, onChanged: (entry) async {
      final connection = connections.items.firstWhereOrNull((element) {
        return entry.key == element.remote.id;
      });
      if (connection != null &&
          entry.value.first.answer != entry.value.second.answer) {
        final connectionData = entry.value.second;
        if (connectionData.offerId == user.id) {
          final answer = connectionData.answer!;
          await connection.setAnswer(answer);
        }
      }
    });
    room.attendees.addDiffListener(onRemoved: (attendee) {
      final connection = connections.items
          .firstWhereOrNull((element) => element.remote.id == attendee.id);
      if (connection != null) {
        connections.removeItem(connection);
        connection.dispose();
      }
    });
  }

  Future<void> exitRoom() async {
    final state = this.state;
    if (state is ConnectedRoomState) {
      return safeAttempt(() async {
        final attendee = state.user;
        state.room.attendees.dispose();
        await _roomClient.exitRoom(attendee);
        if (state.room.attendees.isEmpty) {
          await _roomClient.closeRoom(state.room);
        }
        dispose();
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
}
