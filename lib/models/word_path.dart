class WordPath {
  final String word;
  final List<int> path;
  bool foundByPlayer;

  WordPath({required this.word, required this.path, this.foundByPlayer = false});

  Map<String, dynamic> toJson() => {
        'w': word,
        'p': path,
        'f': foundByPlayer,
      };

  factory WordPath.fromJson(Map<String, dynamic> j) => WordPath(
        word: j['w'] as String,
        path: List<int>.from(j['p'] as List),
        foundByPlayer: j['f'] as bool,
      );

  int get score {
    final n = word.length;
    if (n <= 4) return 1;
    if (n == 5) return 2;
    if (n == 6) return 3;
    if (n == 7) return 5;
    return 11;
  }
}
