import 'package:equatable/equatable.dart';

class AvailableUser extends Equatable {
  final String id;
  final String name;
  final bool anonymous;

  const AvailableUser(this.id, this.name, this.anonymous);
  factory AvailableUser.fromJson(Map<String, dynamic> json) {
    return AvailableUser(json['id'], json['name'], json['anonymous']);
  }

  @override
  get props => [
        id,
        name,
        anonymous,
      ];

  Map<String, dynamic> get json {
    return {
      'id': id,
      'name': name,
      'anonymous': anonymous,
    };
  }
}
