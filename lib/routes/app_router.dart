import 'package:auto_route/auto_route.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/helpers/guards/auth.dart';
import 'package:webrtc_test/helpers/guards/room.dart';
import 'package:webrtc_test/routes/app_router.gr.dart';
import 'package:webrtc_test/ui/screens/loading.dart';
import 'package:webrtc_test/ui/screens/login.dart';
import 'package:webrtc_test/ui/screens/room.dart';
import 'package:webrtc_test/ui/screens/rooms.dart';
import 'package:webrtc_test/ui/screens/signup.dart';
import 'package:webrtc_test/ui/screens/splash.dart';

final appRouterProvider = Provider((ref) {
  return AppRouter(
    roomGuard: RoomGuard(),
    authRedirectGuard: AuthRedirectGuard(ref),
  );
});

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(page: SplashScreen, initial: true),
    AutoRoute(page: LoadingScreen),
    AutoRoute(page: SignupScreen),
    AutoRoute(page: LoginScreen),
    AutoRoute(page: RoomsScreen, guards: [AuthRedirectGuard]),
    AutoRoute(page: RoomScreen, guards: [RoomGuard]),
  ],
)
class $AppRouter {}
