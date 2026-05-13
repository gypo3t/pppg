import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_settings.dart';
import 'models/session_stats.dart';
import 'services/dictionary_service.dart';
import 'route_observer.dart';
import 'screens/edition_screen.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([AppSettings.load(), SessionStats.load(), DictionaryService.load()]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(MaterialApp(
    theme: AppTheme.light,
    navigatorObservers: [routeObserver],
    home: const EditionScreen(),
  ));
}
