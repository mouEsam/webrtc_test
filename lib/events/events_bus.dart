/// ui EventBus response about showing any ui changes from package
abstract class AppEventBus {
  const AppEventBus();
}

class InternetConnectionFailedEvent extends AppEventBus {
  const InternetConnectionFailedEvent();
}
