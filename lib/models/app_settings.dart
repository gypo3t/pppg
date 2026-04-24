import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._();

  static const _kGridSize = 'gridSize';
  static const _kGameDuration = 'gameDuration';
  static const _kShowTextInput = 'showTextInput';
  static const _kShowMaxStats = 'showMaxStats';

  static int gridSize = 4;
  static int gameDuration = 180;
  static bool showTextInput = false;
  static bool showMaxStats = true;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    gridSize = p.getInt(_kGridSize) ?? 4;
    gameDuration = p.getInt(_kGameDuration) ?? 180;
    showTextInput = p.getBool(_kShowTextInput) ?? false;
    showMaxStats = p.getBool(_kShowMaxStats) ?? true;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGridSize, gridSize);
    await p.setInt(_kGameDuration, gameDuration);
    await p.setBool(_kShowTextInput, showTextInput);
    await p.setBool(_kShowMaxStats, showMaxStats);
  }
}
