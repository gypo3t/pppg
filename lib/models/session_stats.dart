import 'package:shared_preferences/shared_preferences.dart';

class SessionStats {
  SessionStats._();

  static const _kGames = 'global_games';
  static const _kPlayerWords = 'global_player_words';
  static const _kSolutionWords = 'global_solution_words';

  // Stats de la session courante
  static int sessionGames = 0;
  static int sessionPlayerWords = 0;
  static int sessionSolutionWords = 0;

  // Stats globales (toutes sessions)
  static int globalGames = 0;
  static int globalPlayerWords = 0;
  static int globalSolutionWords = 0;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    globalGames = p.getInt(_kGames) ?? 0;
    globalPlayerWords = p.getInt(_kPlayerWords) ?? 0;
    globalSolutionWords = p.getInt(_kSolutionWords) ?? 0;
  }

  static void recordGame({
    required int playerWords,
    required int solutionWords,
  }) {
    sessionGames++;
    sessionPlayerWords += playerWords;
    sessionSolutionWords += solutionWords;

    globalGames++;
    globalPlayerWords += playerWords;
    globalSolutionWords += solutionWords;
    _saveGlobal();
  }

  static Future<void> _saveGlobal() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGames, globalGames);
    await p.setInt(_kPlayerWords, globalPlayerWords);
    await p.setInt(_kSolutionWords, globalSolutionWords);
  }
}
