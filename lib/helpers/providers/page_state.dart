import 'package:webrtc_test/exceptions/page_error.dart';

typedef Builder<W> = W Function();
typedef ArgBuilder<W, A> = W Function(A);

abstract class PageState {
  const PageState();
  W? when<W, Data>({
    Builder<W>? onInitial,
    Builder<W>? onLoading,
    ArgBuilder<W, Data>? onData,
    ArgBuilder<W, PageError>? onError,
    ArgBuilder<W, PageState>? onOther,
  }) {
    if (this is InitialPageState && onInitial != null) {
      return onInitial();
    } else if (this is LoadingPageState && onLoading != null) {
      return onLoading();
    } else if (this is LoadedPageState<Data> && onData != null) {
      return onData((this as LoadedPageState<Data>).data);
    } else if (this is ErrorPageState && onError != null) {
      return onError((this as ErrorPageState).error);
    } else {
      return onOther?.call(this);
    }
  }
}

class InitialPageState extends PageState {
  const InitialPageState();
}

class LoadingPageState extends PageState {
  const LoadingPageState();
}

class LoadedPageState<T> extends PageState {
  final T data;
  const LoadedPageState(this.data);
}

class ErrorPageState extends PageState {
  final PageError error;
  const ErrorPageState(this.error);
}
