import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart' hide Toast;
import 'package:webrtc_test/events/event_overlay.dart';
import 'package:webrtc_test/events/ui_events.dart';
import 'package:webrtc_test/routes/app_router.dart';
import 'package:webrtc_test/services/providers/conductor/route_conductor.dart';

class App extends ConsumerStatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final _appRouter = ref.read(appRouterProvider);
  late final _routeConductor = ref.read(routeConductorProvider(_appRouter));

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp.router(
        title: "Kortobaa's Boilerplate",
        routerDelegate: AutoRouterDelegate(
          _appRouter,
          navigatorObservers: () => [
            _routeConductor.observer,
          ],
        ),
        routeInformationParser: _appRouter.defaultRouteParser(),
        builder: (context, widget) {
          return AppEventOverlay(
            onListen: (event) {
              if (event is OperationFailedEvent) {
                showDialog(
                  context: _appRouter.navigatorKey.currentContext!,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Error'),
                      content: Text(event.error.message),
                      actions: [
                        TextButton(
                          onPressed: AutoRouter.of(context).pop,
                          child: const Text('OK'),
                        ),
                        if (event.error.retry != null)
                          ElevatedButton(
                            onPressed: event.error.retry,
                            child: const Text('Retry'),
                          ),
                      ],
                    );
                  },
                );
              }
              // set action based on what is event .. you can add more events in ui_event_bus.dart file
              // if (event is DioErrorEvent) {
              //   UiHelpers.showNotification(event.message);
              // } else if (event is UserLoggedEvent) {
              //   UiHelpers.showNotification(LocaleKeys.alerts_success_login.tr());
              // } else if (event is InternetConnectionFailedEvent) {
              //   Fluttertoast.showToast(
              //     msg: LocaleKeys.alerts_internet_connection_failed.tr(),
              //     toastLength: Toast.LENGTH_SHORT,
              //     gravity: ToastGravity.BOTTOM,
              //     fontSize: 16.0,
              //   );
              // }
            },
            child: SizedBox(child: widget),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // * App Scope Disposer
    // Dispose any opened resources that is scoped to the whole application
    // such as Database Instances, Errors Handlers Streams, etc ...
  }
}
