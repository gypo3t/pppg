import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_path.dart';

class RecentGame {
  final List<WordPath> words;
  final List<String> letters;
  final int gridSize;

  const RecentGame({
    required this.words,
    required this.letters,
    required this.gridSize,
  });

  Map<String, dynamic> toJson() => {
        'words': words.map((w) => w.toJson()).toList(),
        'letters': letters,
        'gs': gridSize,
      };

  factory RecentGame.fromJson(Map<String, dynamic> j) => RecentGame(
        words: (j['words'] as List)
            .map((e) => WordPath.fromJson(e as Map<String, dynamic>))
            .toList(),
        letters: List<String>.from(j['letters'] as List),
        gridSize: j['gs'] as int,
      );
}

class GameRecord {
  final DateTime timestamp;
  final int playerWords;
  final int solutionWords;
  final int playerScore;
  final int totalScore;

  const GameRecord({
    required this.timestamp,
    required this.playerWords,
    required this.solutionWords,
    required this.playerScore,
    required this.totalScore,
  });

  Map<String, dynamic> toJson() => {
        'at': timestamp.toIso8601String(),
        'pw': playerWords,
        'sw': solutionWords,
        'ps': playerScore,
        'tot': totalScore,
      };

  factory GameRecord.fromJson(Map<String, dynamic> j) => GameRecord(
        timestamp: DateTime.parse(j['at'] as String),
        playerWords: j['pw'] as int,
        solutionWords: j['sw'] as int,
        playerScore: j['ps'] as int,
        totalScore: j['tot'] as int,
      );
}

class SessionStats {
  SessionStats._();

  static const _kGames = 'global_games';
  static const _kPlayerWords = 'global_player_words';
  static const _kSolutionWords = 'global_solution_words';
  static const _kHistory = 'game_history';
  static const _kRecent = 'recent_games';
  static const _recentMax = 5;

  // Dernières parties jouées (persistées)
  static List<RecentGame> recentGames = [];

  static List<WordPath>? get lastWords => recentGames.lastOrNull?.words;
  static List<String>? get lastLetters => recentGames.lastOrNull?.letters;
  static int? get lastGridSize => recentGames.lastOrNull?.gridSize;

  static void recordLastGame({
    required List<WordPath> words,
    required List<String> letters,
    required int gridSize,
  }) {
    recentGames.add(RecentGame(
      words: List.of(words),
      letters: List.of(letters),
      gridSize: gridSize,
    ));
    if (recentGames.length > _recentMax) {
      recentGames.removeAt(0);
    }
    _saveRecent();
  }

  // Stats de session (conservées pour stats_card)
  static int sessionGames = 0;
  static int sessionPlayerWords = 0;
  static int sessionSolutionWords = 0;

  // Stats globales (toutes sessions)
  static int globalGames = 0;
  static int globalPlayerWords = 0;
  static int globalSolutionWords = 0;

  // Historique des parties
  static List<GameRecord> gameHistory = [];

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    globalGames = p.getInt(_kGames) ?? 0;
    globalPlayerWords = p.getInt(_kPlayerWords) ?? 0;
    globalSolutionWords = p.getInt(_kSolutionWords) ?? 0;

    final histJson = p.getString(_kHistory);
    if (histJson != null) {
      final list = jsonDecode(histJson) as List;
      gameHistory = list
          .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final recentJson = p.getString(_kRecent);
    if (recentJson != null) {
      final list = jsonDecode(recentJson) as List;
      recentGames = list
          .map((e) => RecentGame.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  static void recordGame({
    required int playerWords,
    required int solutionWords,
    required int playerScore,
    required int totalScore,
  }) {
    sessionGames++;
    sessionPlayerWords += playerWords;
    sessionSolutionWords += solutionWords;

    globalGames++;
    globalPlayerWords += playerWords;
    globalSolutionWords += solutionWords;

    gameHistory.add(GameRecord(
      timestamp: DateTime.now(),
      playerWords: playerWords,
      solutionWords: solutionWords,
      playerScore: playerScore,
      totalScore: totalScore,
    ));

    _saveGlobal();
  }

  static Future<void> resetGlobal() async {
    globalGames = 0;
    globalPlayerWords = 0;
    globalSolutionWords = 0;
    gameHistory = [];
    recentGames = [];
    final p = await SharedPreferences.getInstance();
    await p.remove(_kGames);
    await p.remove(_kPlayerWords);
    await p.remove(_kSolutionWords);
    await p.remove(_kHistory);
    await p.remove(_kRecent);
  }

  static Future<void> _saveRecent() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kRecent,
      jsonEncode(recentGames.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> _saveGlobal() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGames, globalGames);
    await p.setInt(_kPlayerWords, globalPlayerWords);
    await p.setInt(_kSolutionWords, globalSolutionWords);
    await p.setString(
      _kHistory,
      jsonEncode(gameHistory.map((r) => r.toJson()).toList()),
    );
  }
}
