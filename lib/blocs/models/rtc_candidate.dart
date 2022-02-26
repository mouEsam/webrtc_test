import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class RtcIceCandidateModel extends Equatable {
  final String? id;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  const RtcIceCandidateModel(this.id, this.candidate, this.sdpMid, this.sdpMLineIndex);

  factory RtcIceCandidateModel.fromCandidate(RTCIceCandidate candidate) {
    return RtcIceCandidateModel(
      null,
      candidate.candidate,
      candidate.sdpMid,
      candidate.sdpMLineIndex,
    );
  }

  RTCIceCandidate get iceCandidate =>
      RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);

  Map<String, dynamic> toMap() => iceCandidate.toMap();

  @override
  get props => [id, candidate, sdpMid, sdpMLineIndex];
}
