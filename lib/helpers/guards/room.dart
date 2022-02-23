import 'package:auto_route/auto_route.dart';
import 'package:webrtc_test/routes/app_router.gr.dart';

class RoomGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final args = resolver.route.args as RoomRouteArgs;
    if (args.availableRoom != null || args.roomName != null) {
      resolver.next(true);
    } else {
      resolver.next(false);
    }
  }
}
