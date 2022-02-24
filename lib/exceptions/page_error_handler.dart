import 'package:event_bus/event_bus.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/events/event.dart';
import 'package:webrtc_test/events/ui_events.dart';
import 'package:webrtc_test/exceptions/page_error.dart';

final pageErrorHandlerProvider =
    Provider((ref) => PageErrorHandler(ref.read(appEventBusProvider)));

class PageErrorHandler {
  final EventBus _eventBut;

  const PageErrorHandler(this._eventBut);

  void handleError(PageError error) {
    if (error is OperationPageError) {
      _eventBut.fire(OperationFailedEvent(error));
    }
  }
}
