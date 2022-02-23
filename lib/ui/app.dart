import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart' hide Toast;
import 'package:webrtc_test/events/event_bus_overlay.dart';
import 'package:webrtc_test/helpers/guards/room.dart';
import 'package:webrtc_test/routes/app_router.gr.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final _appRouter = AppRouter(
    roomGuard: RoomGuard(),
  );

  @override
  Widget build(BuildContext context) {
    // App Localization
    return OverlaySupport(
      child: AppEventBusOverlay(
        onListen: (event) {
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
        child: MaterialApp.router(
          title: "Kortobaa 's Boilerplate",
          routerDelegate: AutoRouterDelegate(_appRouter),
          routeInformationParser: _appRouter.defaultRouteParser(),
        ),
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
