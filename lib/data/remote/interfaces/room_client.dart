import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/blocs/models/connection.dart';
import 'package:webrtc_test/blocs/models/room.dart';
import 'package:webrtc_test/blocs/models/rtc_candidate.dart';
import 'package:webrtc_test/blocs/models/user.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/tuple.dart';

abstract class IRoomClient {
  Future<Tuple2<Room, Attendee>> createRoom(
    String roomName,
    UserAccount user,
  );

  Future<Tuple2<Room, Attendee>> joinRoom(
    AvailableRoom room,
    UserAccount user,
    RTCSessionDescription offer,
  );

  Future<List<AvailableRoom>> getAvailableRooms();

  ListDiffNotifier<RtcIceCandidateModel> getUserCandidates(
    Room room,
    UserAccount user,
    Attendee attendee,
    Connection connection,
  );

  Future<void> addCandidate(
    Attendee attendee,
    RtcIceCandidateModel candidate,
    Connection connection,
  );

  Future<void> exitRoom(Attendee attendee);

  Future<void> closeRoom(Room room);

  Future<void> addConnection(
      Room room, UserAccount userAccount, Connection connection);
}
