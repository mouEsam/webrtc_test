import 'dart:async';
import 'dart:developer';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webrtc_test/events/event.dart';
import 'package:webrtc_test/events/navigation_events.dart';
import 'package:webrtc_test/providers/auth/auth_notifier.dart';
import 'package:webrtc_test/providers/auth/user_state.dart';
import 'package:webrtc_test/routes/app_router.gr.dart';
import 'package:webrtc_test/services/interfaces/conductor/route_conductor.dart';
import 'package:webrtc_test/services/interfaces/conductor/ticket_stamper.dart';
import 'package:webrtc_test/services/providers/conductor/ticket_stamper.dart';

part 'conductor_state.dart';

final routeConductorProvider =
    Provider.family<IRouteConductor, AppRouter>((ref, AppRouter router) {
  return RouteConductor(
    router,
    ref.read(appEventBusProvider),
    ref.read(authStateProvider.stream),
  );
});

class RouteConductor extends StateNotifier<ConductorState>
    implements IRouteConductor {
  final AppRouter _router;
  final EventBus _eventBus;
  final Stream<UserState> _userState;

  late final StreamSubscription _busSubscription;
  late final StreamSubscription _subscription;

  final TicketStamperObserver _observer = TicketStamperObserver();

  @override
  TicketStamper get stamper => _observer;
  @override
  NavigatorObserver get observer => _observer;

  RouteConductor(this._router, this._eventBus, this._userState)
      : super(InitialConductorState()) {
    final beginStream =
        _eventBus.on<BeginNavigationEvent>().first.asStream().cast<void>();
    final stream = _combine(
      beginStream,
      _userState,
      StatesComplex.new,
    );
    _subscription = stream
        .asyncMap(createState)
        .whereType<ConductorState>()
        .listen((state) {
      this.state = state;
    });
    _busSubscription =
        _eventBus.on<NavigationEvent>().listen(handleNavigationEvent);
    this
        .stream
        .distinct((a, b) => a.runtimeType == b.runtimeType)
        .where((event) => !event.isHandled)
        .listen((event) {
      event._complete(Future.sync(() => handleState(event)));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    _busSubscription.cancel();
  }

  Stream<StatesComplex> _combine<A, B>(
    Stream<A> s1,
    Stream<B> s2,
    StatesComplex Function(B v2) combiner,
  ) {
    return CombineLatestStream.combine2<A, B, StatesComplex>(
      s1,
      s2,
      (_, v) => combiner(v),
    );
  }

  void handleNavigationEvent(NavigationEvent event) async {
    if (event is AuthRequiredNavigationEvent) {
      await _handleAuthRequired<AuthenticatedUserState>(event.onResult);
    } else if (event is ReAuthRequiredNavigationEvent) {
      await _handleAuthRequired<ReAuthenticatedUserState>(event.onResult);
    }
  }

  Future<void> _handleAuthRequired<T extends UserState>(
      ValueChanged<bool>? onResult) async {
    final finished = _router.push(const LoginRoute());
    if (onResult != null) {
      _subscription.pause(Future(() async {
        final isAuth = _userState.firstWhere((element) => element is T);
        final done = await Future.any([isAuth, finished]);
        if (done is AuthenticatedUserState) {
          state = MainConductorState(0);
          onResult.call(true);
        } else {
          onResult.call(false);
        }
      }));
    }
  }

  FutureOr<ConductorState?> createState(StatesComplex states) {
    final userState = states.userState;
    log("Received user state ${userState.runtimeType}");
    if (userState is LoadingUserState) {
      return LoadingConductorState();
    } else if (userState is LoggedInUserState) {
      return MainConductorState();
    } else if (userState is LoggedOutUserState) {
      return AuthRequiredConductorState();
    }
    return null;
  }

  void handleState(ConductorState state) {
    log("Received conductor state ${state.runtimeType}");
    _router.removeWhere((route) {
      return [
        LoadingRoute.name,
        SplashRoute.name,
        SignupRoute.name,
        LoginRoute.name,
      ].contains(route.name);
    });
    if (state is LoadingConductorState) {
      _router.push(const LoadingRoute());
    } else if (state is AuthRequiredConductorState) {
      _router.push(const LoginRoute());
    } else if (state is MainConductorState) {
      _router.push(const RoomsRoute());
    }
  }
}
