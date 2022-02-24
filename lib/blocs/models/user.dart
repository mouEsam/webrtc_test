import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAccount extends Equatable {
  final String id;
  final String name;
  final User _user;

  const UserAccount(this.id, this.name, this._user);
  factory UserAccount.fromJson(Map<String, dynamic> json, User user) {
    return UserAccount(json['id'], json['name'], user);
  }

  @override
  get props => [
        id,
        name,
      ];

  Map<String, dynamic> get json {
    return {
      'id': id,
      'name': name,
      'anonymous': _user.isAnonymous,
    };
  }
}
