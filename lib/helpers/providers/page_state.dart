import 'package:webrtc_test/exceptions/page_error.dart';

abstract class PageState {
  const PageState();
}

class InitialPageState extends PageState {
  const InitialPageState();
}

class LoadingPageState extends PageState {
  const LoadingPageState();
}

class LoadedPageState extends PageState {
  const LoadedPageState();
}

class ErrorPageState extends PageState {
  final PageError error;
  const ErrorPageState(this.error);
}
