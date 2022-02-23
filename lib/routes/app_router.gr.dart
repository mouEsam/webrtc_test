// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i4;

import '../blocs/models/available_room.dart' as _i6;
import '../helpers/guards/room.dart' as _i5;
import '../ui/screens/room.dart' as _i2;
import '../ui/screens/rooms.dart' as _i1;

class AppRouter extends _i3.RootStackRouter {
  AppRouter(
      {_i4.GlobalKey<_i4.NavigatorState>? navigatorKey,
      required this.roomGuard})
      : super(navigatorKey);

  final _i5.RoomGuard roomGuard;

  @override
  final Map<String, _i3.PageFactory> pagesMap = {
    RoomsRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.RoomsScreen());
    },
    RoomRoute.name: (routeData) {
      final args = routeData.argsAs<RoomRouteArgs>();
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.RoomScreen(
              key: args.key,
              name: args.name,
              availableRoom: args.availableRoom,
              roomName: args.roomName));
    }
  };

  @override
  List<_i3.RouteConfig> get routes => [
        _i3.RouteConfig(RoomsRoute.name, path: '/'),
        _i3.RouteConfig(RoomRoute.name,
            path: '/room-screen', guards: [roomGuard])
      ];
}

/// generated route for
/// [_i1.RoomsScreen]
class RoomsRoute extends _i3.PageRouteInfo<void> {
  const RoomsRoute() : super(RoomsRoute.name, path: '/');

  static const String name = 'RoomsRoute';
}

/// generated route for
/// [_i2.RoomScreen]
class RoomRoute extends _i3.PageRouteInfo<RoomRouteArgs> {
  RoomRoute(
      {_i4.Key? key,
      required String name,
      _i6.AvailableRoom? availableRoom,
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

  final _i4.Key? key;

  final String name;

  final _i6.AvailableRoom? availableRoom;

  final String? roomName;

  @override
  String toString() {
    return 'RoomRouteArgs{key: $key, name: $name, availableRoom: $availableRoom, roomName: $roomName}';
  }
}
