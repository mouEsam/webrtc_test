import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webrtc_test/blocs/models/user.dart';
import 'package:webrtc_test/data/remote/apis/firebase.dart';
import 'package:webrtc_test/data/remote/interfaces/auth_client.dart';

final authClientProvider = Provider<IAuthClient>((ref) {
  return AuthClient(ref.read(fireAuthProvider), ref.read(firestoreProvider));
});

class AuthClient implements IAuthClient {
  static const _usersCollection = 'Users';
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  const AuthClient(this._firebaseAuth, this._firebaseFirestore);

  DocumentReference<UserAccount> getUserRef(User user) {
    return _firebaseFirestore
        .collection(_usersCollection)
        .doc(user.uid)
        .withConverter(fromFirestore: (doc, options) {
      final json = doc.data()!;
      final account = UserAccount.fromJson(json, user);
      return account;
    }, toFirestore: (user, options) {
      final json = user.json;
      return json;
    });
  }

  Stream<UserAccount?> get currentUser {
    return _firebaseAuth.userChanges().switchMap((user) {
      if (user != null) {
        return getUserRef(user).snapshots().map((event) => event.data());
      } else {
        return Stream.value(null);
      }
    }).handleError((_) => null);
  }

  Future<void> signup(String name, String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user!;
    final account = UserAccount(user.uid, name, user);
    await getUserRef(user).set(account);
  }

  Future<void> login(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    userCredential.user!;
  }

  Future<void> anonymousLogin(String name) async {
    final userCredential = await _firebaseAuth.signInAnonymously();
    final user = userCredential.user!;
    final account = UserAccount(user.uid, name, user);
    await getUserRef(user).set(account);
  }
}
