import 'package:equatable/equatable.dart';
import 'package:webrtc_test/blocs/models/connection.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';
import 'package:webrtc_test/helpers/utils/map_diff_notifier.dart';

import 'attendee.dart';

class Room extends Equatable {
  final String id;
  final String name;
  final String hostId;
  final ListDiffNotifier<Attendee> attendees;
  final MapDiffNotifier<String, Connection> connections;

  const Room(this.id, this.name, this.hostId, this.attendees, this.connections);

  @override
  get props => [
        id,
        name,
        hostId,
      ];
}
