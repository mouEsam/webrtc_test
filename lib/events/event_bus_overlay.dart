import 'dart:async';
import 'dart:developer';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'events_bus.dart';

final appEventBusProviderRef = Provider<EventBus>((ref) => EventBus());

/// do not forget wrap this stateful widget  in app.dart
/// response with show custom ui from package [dio_errors , auth_status,]
/// you can add your custom events by inherit new class form [AppEventBus] in your app code
class AppEventBusOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final Function(AppEventBus) onListen;
  const AppEventBusOverlay({
    Key? key,
    required this.child,
    required this.onListen,
  }) : super(key: key);

  @override
  _UiEventBusOverlayState createState() => _UiEventBusOverlayState();
}

class _UiEventBusOverlayState extends ConsumerState<AppEventBusOverlay>
    with WidgetsBindingObserver {
  late StreamSubscription _subscription;

  void _initEventBus(WidgetRef ref) {
    final eventBus = ref.read(appEventBusProviderRef);

    _subscription = eventBus.on<AppEventBus>().listen((event) {
      log(event.toString(), name: 'auth package on listen fire');
      widget.onListen(event);
    });
  }

  @override
  void initState() {
    log('initState AppEventBusOverlay');

    _initEventBus(ref);

    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log("$state in AppEventBusOverlay");
    if (state == AppLifecycleState.resumed) {
      _subscription.resume();
    } else {
      if (!_subscription.isPaused) {
        _subscription.pause();
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    log('dispose AppEventBusOverlay');

    _subscription.cancel();

    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('build AppEventBusOverlay');
    return widget.child;
  }
}
