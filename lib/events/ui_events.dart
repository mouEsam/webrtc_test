import 'package:webrtc_test/events/event.dart';
import 'package:webrtc_test/exceptions/page_error.dart';

/// ui EventBus response about showing any ui changes from package
abstract class UIEvent extends AppEvent {
  const UIEvent();
}

class InternetConnectionFailedEvent extends UIEvent {
  const InternetConnectionFailedEvent();
}

class OperationFailedEvent extends UIEvent {
  final OperationPageError error;
  const OperationFailedEvent(this.error);
}
