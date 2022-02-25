import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Connection extends Equatable {
  final List<String> parties;
  final String? offerId;
  final String? answerId;
  final RTCSessionDescription offer;
  final RTCSessionDescription? answer;

  const Connection(
    this.parties,
    this.offerId,
    this.answerId,
    this.offer,
    this.answer,
  );

  Connection setAnswer(RTCSessionDescription answer) {
    return Connection(parties, offerId, answerId, offer, answer);
  }

  @override
  get props => [
        parties,
        offerId,
        answerId,
        offer,
        answer,
      ];
}
