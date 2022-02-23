import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';

import 'attendee.dart';

class Room extends Equatable {
  final String id;
  final String name;
  final RTCSessionDescription offer;
  final ListDiffNotifier<Attendee> attendees;

  const Room(this.id, this.name, this.offer, this.attendees);

  @override
  get props => [
        id,
        name,
        offer.toMap(),
      ];
}
