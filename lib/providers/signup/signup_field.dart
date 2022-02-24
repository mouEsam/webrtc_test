import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/data/remote/apis/auth_client.dart';
import 'package:webrtc_test/exceptions/page_error.dart';
import 'package:webrtc_test/exceptions/page_error_handler.dart';
import 'package:webrtc_test/helpers/providers/page_notifier.dart';
import 'package:webrtc_test/helpers/providers/page_state.dart';

final signupFieldProvider =
    StateNotifierProvider.autoDispose<SignupField, PageState>(
  (ref) {
    return SignupField(
      ref.read(authClientProvider),
      ref.read(pageErrorHandlerProvider),
    );
  },
);

class SignupField extends PageNotifier {
  final nameField = TextEditingController();
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  final AuthClient _authClient;

  SignupField(this._authClient, PageErrorHandler errorHandler)
      : super(errorHandler);

  @override
  void dispose() {
    super.dispose();
    nameField.dispose();
    emailField.dispose();
    passwordField.dispose();
  }

  Future<void> signup() {
    return safeAttempt(
      () async {
        await _authClient.signup(
            nameField.text, emailField.text, passwordField.text);
        return const LoadedPageState();
      },
      errorFactory: OperationPageError.fromError,
    );
  }
}
