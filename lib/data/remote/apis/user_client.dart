import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webrtc_test/blocs/models/available_user.dart';
import 'package:webrtc_test/data/remote/apis/firebase.dart';
import 'package:webrtc_test/data/remote/interfaces/user_client.dart';

final userClientProvider = Provider<IUserClient>((ref) {
  return UserClient(ref.read(firestoreProvider));
});

class UserClient implements IUserClient {
  static const _usersCollection = 'Users';
  final FirebaseFirestore _firebaseFirestore;

  const UserClient(this._firebaseFirestore);

  CollectionReference<AvailableUser> get usersRef {
    return _firebaseFirestore.collection(_usersCollection).withConverter(
        fromFirestore: (doc, options) {
      final json = doc.data()!;
      final account = AvailableUser.fromJson(json);
      return account;
    }, toFirestore: (user, options) {
      final json = user.json;
      return json;
    });
  }

  Future<List<AvailableUser>> getAvailableUsers() async {
    final ref = usersRef;
    return ref.get().then((value) => value.docs.map((e) => e.data()).toList());
  }
}
