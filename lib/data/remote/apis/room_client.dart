import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/blocs/models/connection.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/blocs/models/user.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';
import 'package:webrtc_test/helpers/utils/box.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/tuple.dart';

import 'firebase.dart';

final roomClientProvider = Provider<IRoomClient>((ref) {
  return RoomClient(ref.read(firestoreProvider), math.Random.secure());
});

class RoomClient implements IRoomClient {
  static const _maxInt = 1 << 31; // safe for js
  static const _roomsCollection = 'AvailableRooms';
  static const _iceCandidates = 'IceCandidates';
  static const _attendeesCollection = 'Attendees';
  static const _connectionsCollection = 'Connections';

  final FirebaseFirestore _firestoreInstance;
  final math.Random random;

  const RoomClient(this._firestoreInstance, this.random);

  CollectionReference<RtcIceCandidateModel> getIceCandidates(
      DocumentReference attendeeDoc) {
    return attendeeDoc.collection(_iceCandidates).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      return RtcIceCandidateModel(
        doc.id,
        json['candidate'],
        json['sdpMid'],
        json['sdpMLineIndex'],
      );
    }, toFirestore: (iceCandidate, options) {
      return iceCandidate.toMap();
    });
  }

  CollectionReference<Connection> getConnections(DocumentReference roomDoc) {
    return roomDoc.collection(_connectionsCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final offer = _createRtcSessionDesc(json['offer']);
      final answerJson = json['answer'];
      final answer =
          answerJson == null ? null : _createRtcSessionDesc(answerJson);
      final parties = json['parties'] as List;
      final offerId = json['offerId'];
      final answerId = json['answerId'];
      return Connection(
        doc.id,
        parties.cast<String>().toList(),
        offerId,
        answerId,
        offer,
        answer,
      );
    }, toFirestore: (connection, options) {
      return {
        'offer': connection.offer.toMap(),
        'answer': connection.answer?.toMap(),
        'parties': connection.parties,
        'offerId': connection.offerId,
        'answerId': connection.answerId,
      };
    });
  }

  CollectionReference<Attendee> getAttendees(
      DocumentReference roomDoc, String userId) {
    return roomDoc.collection(_attendeesCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      return Attendee(
        doc.id,
        json['name'],
        roomDoc.id,
        json['secureId'],
      );
    }, toFirestore: (attendee, options) {
      return {
        'name': attendee.name,
        'secureId': attendee.secureId,
      };
    });
  }

  RTCSessionDescription _createRtcSessionDesc(Map<String, dynamic> json) {
    final answer = RTCSessionDescription(json['sdp'], json['type']);
    return answer;
  }

  CollectionReference<Room> getRooms(String userId) {
    return _firestoreInstance.collection(_roomsCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final name = json['name'];
      final hostId = json['hostId'];
      final _subBox = Box<StreamSubscription>();
      final attendees =
          ListDiffNotifier<Attendee>((_) => _subBox.data.cancel());
      _subBox.data =
          getAttendees(doc.reference, userId).snapshots().listen((event) {
        log("Some attendees changes here ${event.size}");
        for (var attendee in event.docChanges) {
          final changeType = attendee.type;
          if (changeType == DocumentChangeType.added) {
            attendees.addItem(attendee.doc.data()!);
          } else if (changeType == DocumentChangeType.removed) {
            attendees.removeItem(attendee.doc.data()!);
          }
        }
      }, cancelOnError: true);
      final _conSubBox = Box<StreamSubscription>();
      final connections =
          MapDiffNotifier<String, Connection>((_) => _conSubBox.data.cancel());
      _conSubBox.data = getConnections(doc.reference)
          .where('parties', arrayContains: userId)
          .snapshots()
          .listen((event) {
        log("Some connections changes here ${event.size}");
        for (var connectionDoc in event.docChanges) {
          final changeType = connectionDoc.type;
          final connection = connectionDoc.doc.data();
          if (connection == null) continue;
          final key = connection.parties
              .firstWhereOrNull((element) => element != userId);
          if (key == null) continue;
          if (changeType == DocumentChangeType.removed) {
            connections.removeItem(key);
          } else {
            connections[key] = connection;
          }
        }
      });
      return Room(doc.id, name, hostId, attendees, connections);
    }, toFirestore: (room, options) {
      return {'name': room.name, 'hostId': room.hostId};
    });
  }

  CollectionReference<AvailableRoom> get availableRooms {
    return _firestoreInstance.collection(_roomsCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final name = json['name'];
      return AvailableRoom(doc.id, name);
    }, toFirestore: (room, options) {
      return {'name': room.name};
    });
  }

  @override
  Future<Tuple2<Room, Attendee>> createRoom(
    String roomName,
    UserAccount user,
  ) async {
    final room =
        Room('', roomName, user.id, ListDiffNotifier(), MapDiffNotifier());
    final roomDoc = await getRooms(user.id).add(room);
    final attendee = createAttendee(user, roomDoc.id, _maxInt);
    final attendeeDoc = getAttendees(roomDoc, user.id).doc(attendee.id);
    await attendeeDoc.set(attendee);
    final savedRoom = roomDoc.get().then((value) => value.data()!);
    final savedAttendee = attendeeDoc.get().then((value) => value.data()!);
    return Tuple2(await savedRoom, await savedAttendee);
  }

  @override
  Future<Tuple2<Room, Attendee>> joinRoom(
    AvailableRoom room,
    UserAccount user,
    RTCSessionDescription offer,
  ) async {
    final roomDoc = getRooms(user.id).doc(room.id);
    final attendee = createAttendee(user, room.id);
    final attendeeDoc = getAttendees(roomDoc, user.id).doc(attendee.id);
    await attendeeDoc.set(attendee);

    final savedRoom = roomDoc.get().then((value) => value.data()!);
    final savedAttendee = attendeeDoc.get().then((value) => value.data()!);

    final connections =
        await roomDoc.collection(_attendeesCollection).get().then((value) {
      return value.docs
          .map((e) => e.id)
          .where((id) => user.id != id)
          .map((id) async {
        final connection = Connection.init([user.id, id], user.id, id, offer);
        await getConnections(roomDoc).add(connection);
        return connection;
      }).toList();
    });
    final r = await savedRoom;
    final a = await savedAttendee;
    await Future.wait(connections);
    return Tuple2(r, a);
  }

  Attendee createAttendee(UserAccount user, String roomId, [int? secureId]) {
    secureId ??= random.nextInt(_maxInt - 1);
    return Attendee(
      user.id,
      user.name,
      roomId,
      secureId,
    );
  }

  @override
  Future<List<AvailableRoom>> getAvailableRooms() async {
    return availableRooms
        .get()
        .then((value) => value.docs.map((e) => e.data()).toList());
  }

  @override
  ListDiffNotifier<RtcIceCandidateModel> getUserCandidates(
    Room room,
    UserAccount user,
    Attendee attendee,
  ) {
    final roomDoc = getRooms(user.id).doc(room.id);
    final attendeeDoc = getAttendees(roomDoc, user.id).doc(attendee.id);
    final candidatesCollection = getIceCandidates(attendeeDoc);
    final _subBox = Box<StreamSubscription>();
    final candidates =
        ListDiffNotifier<RtcIceCandidateModel>((_) => _subBox.data.cancel());
    _subBox.data = candidatesCollection.snapshots().listen((event) {
      for (var candidate in event.docChanges) {
        final changeType = candidate.type;
        if (changeType == DocumentChangeType.added) {
          candidates.addItem(candidate.doc.data()!);
        } else if (changeType == DocumentChangeType.removed) {
          candidates.removeItem(candidate.doc.data()!);
        }
      }
    });
    if (attendee.id == user.id) {
      candidates.addDiffListener(onAdded: (candidate) {
        if (candidate.id == null) {
          candidates.removeItem(candidate);
          addCandidate(attendee, candidate).onError(
            (error, _) => candidates.addItem(candidate),
          );
        }
      });
    }
    return candidates;
  }

  @override
  Future<void> addCandidate(
      Attendee attendee, RtcIceCandidateModel candidate) async {
    final roomDoc = getRooms(attendee.id).doc(attendee.roomId);
    final attendeeDoc = getAttendees(roomDoc, attendee.id).doc(attendee.id);
    await getIceCandidates(attendeeDoc).add(candidate);
  }

  @override
  Future<void> addConnection(
      Room room, UserAccount userAccount, Connection connection) {
    final roomDoc = getRooms(userAccount.id).doc(room.id);
    final connectionDoc = getConnections(roomDoc).doc(connection.id);
    return connectionDoc.set(connection);
  }

  @override
  Future<void> exitRoom(Attendee attendee) async {
    final roomDoc = getRooms(attendee.id).doc(attendee.roomId);
    final attendeeDoc = getAttendees(roomDoc, attendee.id).doc(attendee.id);
    await attendeeDoc.delete();
  }

  @override
  Future<void> closeRoom(Room room) async {
    final roomDoc = getRooms("").doc(room.id);
    await roomDoc.delete();
  }
}
