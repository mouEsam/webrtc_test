import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/blocs/models/user.dart';
import 'package:webrtc_test/blocs/providers/auth/user_notifier.dart';
import 'package:webrtc_test/blocs/providers/auth/user_state.dart';
import 'package:webrtc_test/blocs/providers/room/room_states.dart';
import 'package:webrtc_test/data/remote/apis/room_client.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';
import 'package:webrtc_test/helpers/utils/box.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
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
  Completer<MediaStream> _localStreamCompleter = Completer();
  final ValueNotifier<MediaStream?> _localStream = ValueNotifier(null);
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

  ValueListenable<MediaStream?> get localStream => _localStream;

  RoomNotifier(
    this._roomClient,
    this._userAccount,
  ) : super(const InitialRoomState()) {
    _userAccount.addListener((state) {
      if (state is AuthenticatedUserState) {
        userAccount = state.userAccount;
      }
    });
    _setupLocalStream(true);
  }

  Future<void> _setupLocalStream([bool initial = false]) async {
    if (_localStreamCompleter.isCompleted) return;
    late final MediaStream? stream;
    try {
      stream = await openUserMedia();
    } catch (e) {
      stream = null;
      if (initial) return;
    }
    log("got stream local $stream");
    _localStream.value = stream;
    if (!_localStreamCompleter.isCompleted) {
      _localStreamCompleter.complete(stream);
    }
  }

  Future<MediaStream> openUserMedia() async {
    try {
      return await navigator.mediaDevices
          .getUserMedia({'video': true, 'audio': false});
    } catch (e) {
      return await createLocalMediaStream(userAccount.id);
    }
  }

  @override
  void dispose() {
    super.dispose();
    connections.dispose();
    _candidates?.dispose();
    _localStream.value?.dispose();
    _localStream.dispose();
  }

  Future<void> createRoom(String roomName, String name) async {
    return safeAttempt(() async {
      await _setupLocalStream();
      final data = await _roomClient.createRoom(name, userAccount);
      final user = data.second;
      final room = data.first;
      _setupUserCandidates(user);
      _setupRoomListeners(
        room,
        user,
      );
      return ConnectedRoomState(
        room: data.first,
        user: data.second,
        connections: connections.items,
      );
    });
  }

  Future<void> joinRoom(AvailableRoom availableRoom, String name) async {
    EstablishedPeerConnection? connection;
    return safeAttempt(() async {
      await _setupLocalStream();
      connection = await _createNativeConnection(configuration);
      final offer = await connection!.createOffer();
      final data = await _roomClient.joinRoom(
        availableRoom,
        userAccount,
        offer,
      );
      final user = data.second;
      final room = data.first;
      _setupUserCandidates(user);
      _setupRoomListeners(
        room,
        user,
        connection,
      );
      return ConnectedRoomState(
        room: data.first,
        user: data.second,
        connections: connections.items,
      );
    }, connection?.dispose);
  }

  void _setupUserCandidates(Attendee user) {
    _candidates ??= ListDiffNotifier();
    _candidates?.addDiffListener(onAdded: (candidate) {
      _roomClient.addCandidate(user, candidate);
    });
  }

  void _setupRoomListeners(
    Room room,
    Attendee user, [
    EstablishedPeerConnection? connection,
  ]) {
    final isOffer = connection != null;
    final connectionBox = Box(connection);
    room.connections.addDiffListener(onAdded: (conData) async {
      final attendee = room.attendees.items.firstWhereOrNull((element) {
        return element.id != user.id && conData.parties.contains(element.id);
      });
      log("added connection ${conData.id} found attendee ${attendee != null}");
      if (attendee == null) return;
      final existingConnection = connections.items.firstWhereOrNull((element) {
        return conData.id == element.id;
      });
      late final PeerConnection peerConnection;
      if (existingConnection != null) {
        peerConnection = existingConnection;
      } else {
        late final EstablishedPeerConnection connection;
        if (connectionBox.hasData && isOffer == conData.isOffer(user)) {
          connection = connectionBox.data;
          connectionBox.data = null;
        } else {
          connection = await _createNativeConnection(
            configuration,
          );
        }
        peerConnection = await PeerConnection.createConnection(
          conData.id!,
          attendee,
          _roomClient.getUserCandidates(
            room,
            userAccount,
            attendee,
          ),
          connection,
        );
        connections.addItem(peerConnection);
      }
      if (conData.isOffer(user)) {
        if (!peerConnection.localSat) {
          await peerConnection.setOffer(offer: conData.offer, remote: false);
        }
        if (!peerConnection.remoteSat && conData.answer != null) {
          await peerConnection.setAnswer(answer: conData.answer, remote: true);
        }
      } else if (conData.isAnswer(user)) {
        if (!peerConnection.remoteSat) {
          await peerConnection.setOffer(offer: conData.offer, remote: true);
        }
        if (!peerConnection.localSat) {
          final answer = await peerConnection.setAnswer(remote: false);
          final newConnection = conData.setAnswer(answer);
          _roomClient.addConnection(room, userAccount, newConnection);
        }
      }
    }, onRemoved: (conData) async {
      final existingConnections = connections.items.where((element) {
        return conData.id == element.id;
      }).toList();
      await _closeConnections(existingConnections, false);
    });
    room.attendees.addDiffListener(onRemoved: (attendee) async {
      final attendeeConnections = connections.items
          .where((element) => element.remote.id == attendee.id)
          .toList();
      await _closeConnections(attendeeConnections);
    });
  }

  Future<void> _closeConnections(List<PeerConnection> existingConnections,
      [bool remove = true]) async {
    for (final connection in existingConnections) {
      connection.localStream = null;
      await connection.dispose();
      if (remove) {
        connections.removeItem(connection);
      }
    }
  }

  Future<EstablishedPeerConnection> _createNativeConnection(
      [Map<String, dynamic>? configuration]) async {
    final localStream = await _localStreamCompleter.future;
    configuration ??= this.configuration;
    _candidates ??= ListDiffNotifier();
    final establishedConnection = await EstablishedPeerConnection.establish(
      configuration,
      _candidates!,
      localStream,
    );
    return establishedConnection;
  }

  Future<void> exitRoom() async {
    final state = this.state;
    if (state is ConnectedRoomState) {
      return safeAttempt(() async {
        final attendee = state.user;
        state.room.attendees.dispose();
        await _roomClient.exitRoom(attendee);
        if (state.room.attendees.length <= 1) {
          await _roomClient.closeRoom(state.room);
        }
        await Future.wait(connections.map((value) => value.dispose()));
        connections.clear();
        _candidates?.dispose();
        _candidates = null;
        _localStreamCompleter = Completer();
        _localStream.value?.dispose();
        _localStream.value = null;
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
