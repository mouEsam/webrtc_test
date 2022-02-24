import 'package:event_bus/event_bus.dart';
import 'package:riverpod/riverpod.dart';

final appEventBusProvider = Provider<EventBus>((ref) => EventBus());

abstract class AppEvent {
  const AppEvent();
}
