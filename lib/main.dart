import 'package:flutter/material.dart';
import 'models/app_settings.dart';
import 'models/session_stats.dart';
import 'route_observer.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([AppSettings.load(), SessionStats.load()]);
  runApp(MaterialApp(
    navigatorObservers: [routeObserver],
    home: const HomeScreen(),
  ));
}
