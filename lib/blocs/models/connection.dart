import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/attendee.dart';

class Connection extends Equatable {
  final String? id;
  final List<String> parties;
  final String? offerId;
  final String? answerId;
  final RTCSessionDescription offer;
  final RTCSessionDescription? answer;

  const Connection(
    this.id,
    this.parties,
    this.offerId,
    this.answerId,
    this.offer,
    this.answer,
  );

  const Connection.init(
    this.parties,
    this.offerId,
    this.answerId,
    this.offer,
  )   : id = null,
        answer = null;

  Connection setAnswer(RTCSessionDescription answer) {
    return Connection(id, parties, offerId, answerId, offer, answer);
  }

  bool isOffer(Attendee user) => offerId == user.id;
  bool isAnswer(Attendee user) => answerId == user.id;

  @override
  get props => [
        id,
        parties,
        offerId,
        answerId,
        offer.sdp,
        answer?.sdp,
      ];
}
