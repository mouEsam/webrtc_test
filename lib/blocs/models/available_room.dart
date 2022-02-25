import 'package:equatable/equatable.dart';

class AvailableRoom extends Equatable {
  final String id;
  final String name;

  const AvailableRoom(this.id, this.name);

  @override
  get props => [id, name];
}
