import 'dart:async';

typedef FutureCallback = FutureOr<void> Function();

abstract class PageError {
  final String message;
  const PageError(this.message);

  factory PageError.fromError(e) {
    final String error = e.toString();
    return GeneralPageError(error);
  }
}

class GeneralPageError extends PageError {
  const GeneralPageError(String message) : super(message);
}

class OperationPageError extends PageError {
  final FutureCallback? retry;
  const OperationPageError(String message, this.retry) : super(message);
  factory OperationPageError.fromError(e) {
    final String error = e.toString();
    return OperationPageError(error, null);
  }
  factory OperationPageError.retry(e, FutureCallback? retry) {
    final String error = e.toString();
    return OperationPageError(error, retry);
  }
}
