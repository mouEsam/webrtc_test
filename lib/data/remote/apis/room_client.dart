import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/data/remote/interfaces/room_client.dart';
import 'package:webrtc_test/helpers/utils/box.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/tuple.dart';

import 'firebase.dart';

final roomClientProvider = Provider<IRoomClient>((ref) {
  return RoomClient(ref.read(firestoreProvider));
});

class RoomClient implements IRoomClient {
  static const _roomsCollection = 'AvailableRooms';
  static const _iceCandidates = 'IceCandidates';
  static const _attendeesCollection = 'Attendees';

  final FirebaseFirestore _firestoreInstance;

  const RoomClient(this._firestoreInstance);

  CollectionReference<RtcIceCandidateModel> getIceCandidates(
      DocumentReference attendeeDoc) {
    return attendeeDoc.collection(_iceCandidates).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      return RtcIceCandidateModel(
        json['candidate'],
        json['sdpMid'],
        json['sdpMLineIndex'],
      );
    }, toFirestore: (iceCandidate, options) {
      return iceCandidate.toMap();
    });
  }

  CollectionReference<Attendee> getAttendees(DocumentReference roomDoc) {
    return roomDoc.collection(_attendeesCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final sessionJson = json['sessionDescription'];
      final session =
          RTCSessionDescription(sessionJson['sdp'], sessionJson['type']);
      final candidatesCollection = getIceCandidates(doc.reference);
      final _subBox = Box<StreamSubscription>();
      final candidates =
          ListDiffNotifier<RtcIceCandidateModel>(() => _subBox.data.cancel());
      _subBox.data = candidatesCollection.snapshots().listen((event) {
        for (var candidate in event.docChanges) {
          final changeType = candidate.type;
          if (changeType == DocumentChangeType.added) {
            candidates.addItem(candidate.doc.data()!);
          } else if (changeType == DocumentChangeType.removed) {
            candidates.removeItem(candidate.doc.data()!);
          }
        }
      }, cancelOnError: true);
      return Attendee(doc.id, json['name'], roomDoc.id, session, candidates);
    }, toFirestore: (attendee, options) {
      return {
        'name': attendee.name,
        'sessionDescription': attendee.sessionDescription.toMap()
      };
    });
  }

  CollectionReference<Room> get rooms {
    return _firestoreInstance.collection(_roomsCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final name = json['name'];
      final offerJson = json['offer'];
      final offer = RTCSessionDescription(offerJson['sdp'], offerJson['type']);
      final _subBox = Box<StreamSubscription>();
      final attendees = ListDiffNotifier<Attendee>(() => _subBox.data.cancel());
      _subBox.data = getAttendees(doc.reference).snapshots().listen((event) {
        log("Some changes here ${event.size}");
        for (var attendee in event.docChanges) {
          final changeType = attendee.type;
          if (changeType == DocumentChangeType.added) {
            attendees.addItem(attendee.doc.data()!);
          } else if (changeType == DocumentChangeType.removed) {
            attendees.removeItem(attendee.doc.data()!);
          }
        }
      }, cancelOnError: true);
      return Room(doc.id, name, offer, attendees);
    }, toFirestore: (room, options) {
      return {'name': room.name, 'offer': room.offer.toMap()};
    });
  }

  CollectionReference<AvailableRoom> get availableRooms {
    return _firestoreInstance.collection(_roomsCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final name = json['name'];
      final offerJson = json['offer'];
      final offer = RTCSessionDescription(offerJson['sdp'], offerJson['type']);
      return AvailableRoom(doc.id, name, offer);
    }, toFirestore: (room, options) {
      return {'name': room.name, 'offer': room.offer.toMap()};
    });
  }

  @override
  Future<Tuple2<Room, Attendee>> createRoom(
    String name,
    String roomName,
    RTCSessionDescription sessionDescription,
  ) async {
    final room = Room('', roomName, sessionDescription, ListDiffNotifier());
    final roomDoc = await rooms.add(room);
    final attendee =
        Attendee('', name, roomDoc.id, sessionDescription, ListDiffNotifier());
    final attendeeDoc = await getAttendees(roomDoc).add(attendee);

    final savedRoom = roomDoc.get().then((value) => value.data()!);
    final savedAttendee = attendeeDoc.get().then((value) => value.data()!);

    return Tuple2(await savedRoom, await savedAttendee);
  }

  @override
  Future<Tuple2<Room, Attendee>> answerRoom(
    AvailableRoom room,
    String name,
    RTCSessionDescription sessionDescription,
  ) async {
    final roomDoc = rooms.doc(room.id);
    final attendee =
        Attendee('', name, rooms.id, sessionDescription, ListDiffNotifier());
    final attendeeDoc = await getAttendees(roomDoc).add(attendee);

    final savedRoom = roomDoc.get().then((value) => value.data()!);
    final savedAttendee = attendeeDoc.get().then((value) => value.data()!);

    return Tuple2(await savedRoom, await savedAttendee);
  }

  @override
  Future<List<AvailableRoom>> getAvailableRooms() async {
    return availableRooms
        .get()
        .then((value) => value.docs.map((e) => e.data()).toList());
  }

  @override
  Future<void> addCandidate(
      Attendee attendee, RtcIceCandidateModel candidate) async {
    final roomDoc = rooms.doc(attendee.roomId);
    final attendeeDoc = getAttendees(roomDoc).doc(attendee.id);
    await getIceCandidates(attendeeDoc).add(candidate);
  }

  @override
  Future<void> exitRoom(Attendee attendee) async {
    final roomDoc = rooms.doc(attendee.roomId);
    final attendeeDoc = getAttendees(roomDoc).doc(attendee.id);
    await attendeeDoc.delete();
  }

  @override
  Future<void> closeRoom(Room room) async {
    final roomDoc = rooms.doc(room.id);
    await roomDoc.delete();
  }
}
