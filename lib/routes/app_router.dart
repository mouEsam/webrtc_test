import 'package:auto_route/auto_route.dart';
import 'package:webrtc_test/helpers/guards/room.dart';
import 'package:webrtc_test/ui/screens/room.dart';
import 'package:webrtc_test/ui/screens/rooms.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(page: RoomsScreen, initial: true),
    AutoRoute(page: RoomScreen, guards: [RoomGuard]),
  ],
)
class $AppRouter {}
