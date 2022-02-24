import 'package:flutter/material.dart';
import 'package:webrtc_test/services/providers/conductor/route_conductor.dart';

import 'ticket_stamper.dart';

abstract class IRouteConductor {
  TicketStamper get stamper;
  NavigatorObserver get observer;
  ConductorState get state;
}
