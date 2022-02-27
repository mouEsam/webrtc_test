import 'package:equatable/equatable.dart';

class Attendee extends Equatable {
  final String id;
  final String name;
  final String roomId;
  final int secureId;

  const Attendee(
    this.id,
    this.name,
    this.roomId,
    this.secureId,
  );

  @override
  get props => [
        id,
        name,
        roomId,
        secureId,
      ];
}
