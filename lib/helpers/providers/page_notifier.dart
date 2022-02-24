import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/exceptions/page_error.dart';
import 'package:webrtc_test/exceptions/page_error_handler.dart';

import 'page_state.dart';

typedef ErrorFactory = PageError Function(Object e);

abstract class PageNotifier extends StateNotifier<PageState> {
  final PageErrorHandler _errorHandler;

  PageNotifier(
    this._errorHandler, {
    PageState initialState = const InitialPageState(),
  }) : super(initialState) {
    addListener((state) {
      if (state is ErrorPageState) {
        _errorHandler.handleError(state.error);
      }
    });
  }

  set safeState(PageState newState) {
    if (mounted) state = newState;
  }

  Future<void> safeAttempt(
    FutureOr<PageState> Function() action, {
    VoidCallback? disposer,
    ErrorFactory? errorFactory,
  }) {
    final completer = Completer();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      completer.complete(Future(() async {
        safeState = const LoadingPageState();
        try {
          safeState = await action();
        } catch (e, s) {
          errorFactory ??= PageError.fromError;
          safeState = ErrorPageState(errorFactory!(e));
          disposer?.call();
        }
      }));
    });
    return completer.future;
  }
}
