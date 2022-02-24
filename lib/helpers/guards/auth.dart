import 'package:auto_route/auto_route.dart';
import 'package:riverpod/riverpod.dart';
import 'package:webrtc_test/events/event.dart';
import 'package:webrtc_test/events/navigation_events.dart';
import 'package:webrtc_test/helpers/utils/extensions.dart';
import 'package:webrtc_test/providers/auth/user_notifier.dart';
import 'package:webrtc_test/providers/auth/user_state.dart';

class AuthRedirectGuard extends AuthGuard {
  AuthRedirectGuard(ProviderRef ref) : super(ref, redirect: true);
}

class AuthGuard extends AutoRouteGuard {
  final ProviderRef ref;
  final bool redirect;
  AuthGuard(this.ref, {this.redirect = false});

  @override
  void onNavigation(resolver, router) async {
    final authState = ref.read(userProvider);
    if (authState is AuthenticatedUserState) {
      resolver.next();
    } else {
      final bus = ref.read(appEventBusProvider);
      bus.fire(
        AuthRequiredNavigationEvent(redirect.ifTrue(() => resolver.next)),
      );
    }
  }
}
