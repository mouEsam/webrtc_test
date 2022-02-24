import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webrtc_test/providers/auth/user_notifier.dart';
import 'package:webrtc_test/providers/auth/user_state.dart';

final authStateProvider = StreamProvider<UserState>((ref) {
  final userStateStream = ref.read(userProvider.notifier);
  final userState = ref.read(userProvider);
  return userStateStream.stream.startWith(userState).map((event) {
    return ref.read(userProvider);
  }).shareValue();
});
