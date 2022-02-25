import 'package:equatable/equatable.dart';
import 'package:webrtc_test/helpers/utils/list_diff_notifier.dart';

import 'rtc_candidate.dart';

class Attendee extends Equatable {
  final String id;
  final String name;
  final String roomId;
  final int secureId;
  final ListDiffNotifier<RtcIceCandidateModel> candidates;

  const Attendee(
    this.id,
    this.name,
    this.roomId,
    this.secureId,
    this.candidates,
  );

  @override
  get props => [
        id,
        name,
        roomId,
        secureId,
      ];
}
