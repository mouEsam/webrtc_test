import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webrtc_test/events/event.dart';
import 'package:webrtc_test/events/navigation_events.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final bus = ref.read(appEventBusProvider);
    Future.delayed(const Duration(seconds: 3), () {
      log("Firing");
      bus.fire(const BeginNavigationEvent());
    });
  }

  @override
  Widget build(context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(),
      ),
    );
  }
}
