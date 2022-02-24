// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i7;
import 'package:flutter/material.dart' as _i8;

import '../blocs/models/available_room.dart' as _i11;
import '../helpers/guards/auth.dart' as _i9;
import '../helpers/guards/room.dart' as _i10;
import '../ui/screens/loading.dart' as _i2;
import '../ui/screens/login.dart' as _i4;
import '../ui/screens/room.dart' as _i6;
import '../ui/screens/rooms.dart' as _i5;
import '../ui/screens/signup.dart' as _i3;
import '../ui/screens/splash.dart' as _i1;

class AppRouter extends _i7.RootStackRouter {
  AppRouter(
      {_i8.GlobalKey<_i8.NavigatorState>? navigatorKey,
      required this.authRedirectGuard,
      required this.roomGuard})
      : super(navigatorKey);

  final _i9.AuthRedirectGuard authRedirectGuard;

  final _i10.RoomGuard roomGuard;

  @override
  final Map<String, _i7.PageFactory> pagesMap = {
    SplashRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.SplashScreen());
    },
    LoadingRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.LoadingScreen());
    },
    SignupRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i3.SignupScreen());
    },
    LoginRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.LoginScreen());
    },
    RoomsRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i5.RoomsScreen());
    },
    RoomRoute.name: (routeData) {
      final args = routeData.argsAs<RoomRouteArgs>();
      return _i7.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i6.RoomScreen(
              key: args.key,
              name: args.name,
              availableRoom: args.availableRoom,
              roomName: args.roomName));
    }
  };

  @override
  List<_i7.RouteConfig> get routes => [
        _i7.RouteConfig(SplashRoute.name, path: '/'),
        _i7.RouteConfig(LoadingRoute.name, path: '/loading-screen'),
        _i7.RouteConfig(SignupRoute.name, path: '/signup-screen'),
        _i7.RouteConfig(LoginRoute.name, path: '/login-screen'),
        _i7.RouteConfig(RoomsRoute.name,
            path: '/rooms-screen', guards: [authRedirectGuard]),
        _i7.RouteConfig(RoomRoute.name,
            path: '/room-screen', guards: [roomGuard])
      ];
}

/// generated route for
/// [_i1.SplashScreen]
class SplashRoute extends _i7.PageRouteInfo<void> {
  const SplashRoute() : super(SplashRoute.name, path: '/');

  static const String name = 'SplashRoute';
}

/// generated route for
/// [_i2.LoadingScreen]
class LoadingRoute extends _i7.PageRouteInfo<void> {
  const LoadingRoute() : super(LoadingRoute.name, path: '/loading-screen');

  static const String name = 'LoadingRoute';
}

/// generated route for
/// [_i3.SignupScreen]
class SignupRoute extends _i7.PageRouteInfo<void> {
  const SignupRoute() : super(SignupRoute.name, path: '/signup-screen');

  static const String name = 'SignupRoute';
}

/// generated route for
/// [_i4.LoginScreen]
class LoginRoute extends _i7.PageRouteInfo<void> {
  const LoginRoute() : super(LoginRoute.name, path: '/login-screen');

  static const String name = 'LoginRoute';
}

/// generated route for
/// [_i5.RoomsScreen]
class RoomsRoute extends _i7.PageRouteInfo<void> {
  const RoomsRoute() : super(RoomsRoute.name, path: '/rooms-screen');

  static const String name = 'RoomsRoute';
}

/// generated route for
/// [_i6.RoomScreen]
class RoomRoute extends _i7.PageRouteInfo<RoomRouteArgs> {
  RoomRoute(
      {_i8.Key? key,
      required String name,
      _i11.AvailableRoom? availableRoom,
      String? roomName})
      : super(RoomRoute.name,
            path: '/room-screen',
            args: RoomRouteArgs(
                key: key,
                name: name,
                availableRoom: availableRoom,
                roomName: roomName));

  static const String name = 'RoomRoute';
}

class RoomRouteArgs {
  const RoomRouteArgs(
      {this.key, required this.name, this.availableRoom, this.roomName});

  final _i8.Key? key;

  final String name;

  final _i11.AvailableRoom? availableRoom;

  final String? roomName;

  @override
  String toString() {
    return 'RoomRouteArgs{key: $key, name: $name, availableRoom: $availableRoom, roomName: $roomName}';
  }
}
