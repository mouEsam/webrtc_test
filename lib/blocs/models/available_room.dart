import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AvailableRoom extends Equatable {
  final String id;
  final String name;
  final RTCSessionDescription offer;

  const AvailableRoom(this.id, this.name, this.offer);

  @override
  get props => [id, name, offer.toMap()];
}
