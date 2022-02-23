import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';

import 'rtc_candidate.dart';

class Attendee extends Equatable {
  final String id;
  final String name;
  final String roomId;
  final RTCSessionDescription sessionDescription;
  final ListDiffNotifier<RtcIceCandidateModel> candidates;

  const Attendee(this.id, this.name, this.roomId, this.sessionDescription,
      this.candidates);

  @override
  get props => [
        id,
        name,
        roomId,
        sessionDescription.toMap(),
      ];
}
