import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webrtc_test/blocs/models/user.dart';
import 'package:webrtc_test/data/remote/apis/auth_client.dart';
import 'package:webrtc_test/providers/auth/user_state.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(authClientProvider));
});

class UserNotifier extends StateNotifier<UserState> {
  final AuthClient _authClient;
  late final StreamSubscription _userSub;

  UserNotifier(this._authClient) : super(const LoadingUserState()) {
    _userSub = _authClient.currentUser
        .map(handleUser)
        .asyncMap((event) {
          final completer = Completer<UserState>();
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            completer.complete(event);
          });
          return completer.future;
        })
        .throttleTime(Duration.zero, trailing: true)
        .listen((event) {
          state = event;
        });
  }

  @override
  void dispose() {
    _userSub.cancel();
    super.dispose();
  }

  UserState handleUser(UserAccount? user) {
    if (user != null) {
      return AuthenticatedUserState(user);
    } else {
      return const UnAuthenticatedUserState();
    }
  }
}