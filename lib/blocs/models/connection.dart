import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Connection extends Equatable {
  final String? id;
  final List<String> parties;
  final String offerId;
  final String answerId;
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
