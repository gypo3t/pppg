import '../models/word_path.dart';

class BoggleSolver {
  static const _maxLen = 15;

  final int _size;
  late final List<List<int>> _adjacency;

  BoggleSolver._(this._size) {
    _adjacency = List.generate(_size * _size, (i) {
      final row = i ~/ _size;
      final col = i % _size;
      return [
        for (int dr = -1; dr <= 1; dr++)
          for (int dc = -1; dc <= 1; dc++)
            if ((dr != 0 || dc != 0) &&
                row + dr >= 0 &&
                row + dr < _size &&
                col + dc >= 0 &&
                col + dc < _size)
              (row + dr) * _size + (col + dc),
      ];
    });
  }

  // dico[length][prefix] = list of words of that length starting with that prefix
  final List<Map<String, List<String>>> _dico =
      List.generate(_maxLen + 1, (_) => {});
  final Map<String, bool> _badStart = {};
  final Map<String, List<int>> _found = {};

  static bool _isAnagram(String word, String available) {
    var remaining = available;
    for (int i = 0; i < word.length; i++) {
      final idx = remaining.indexOf(word[i]);
      if (idx < 0) return false;
      remaining = remaining.substring(0, idx) + remaining.substring(idx + 1);
    }
    return true;
  }

  void _loadAnagram(String content, String gridLetters) {
    for (final raw in content.split(RegExp(r'[\r\n]+'))) {
      final word = raw.trim().toUpperCase();
      if (word.isEmpty || word.length < 3 || word.length > _maxLen) continue;
      if (_isAnagram(word, gridLetters)) _addWord(word);
    }
  }

  void _addWord(String w) {
    final map = _dico[w.length];
    for (int n = 0; n < w.length; n++) {
      (map[w.substring(0, n)] ??= []).add(w);
    }
  }

  List<String> _getList(int length, String alpha, int prefixLen) {
    if (length < 0 || length > _maxLen || prefixLen > alpha.length) {
      return const [];
    }
    return _dico[length][alpha.substring(0, prefixLen)] ?? const [];
  }

  // Returns: 0=dead end, 1=prefix only, 2=word (terminal), 3=word + longer words exist
  int _checkWord(String str) {
    final n = str.length;
    int result = 0;

    if (_getList(n, str, n - 1).contains(str)) result = 2;

    for (int i = _maxLen; i > n; i--) {
      for (final word in _getList(i, str, n - 1)) {
        if (word.startsWith(str)) {
          result += 1;
          break;
        }
      }
      if (result.isOdd) break;
    }

    return result;
  }

  void _seekSoluce(
    List<String> letters,
    List<int> path,
    String word,
    List<bool> visited,
  ) {
    final last = path.last;
    for (final n in _adjacency[last]) {
      if (visited[n] || path.length >= _maxLen) continue;

      final newWord = word + letters[n];
      int check;

      if (newWord.length <= 2) {
        check = 1;
      } else if (_badStart.containsKey(newWord)) {
        continue;
      } else if (_found.containsKey(newWord)) {
        check = 1;
      } else {
        check = _checkWord(newWord);
      }

      if (check == 0) {
        _badStart[newWord] = true;
        continue;
      }

      visited[n] = true;
      path.add(n);

      if (check >= 2) {
        _found[newWord] = List.of(path);
        if (check == 2) {
          _badStart[newWord] = true;
          path.removeLast();
          visited[n] = false;
          continue;
        }
      }

      _seekSoluce(letters, path, newWord, visited);

      path.removeLast();
      visited[n] = false;
    }
  }

  static (List<WordPath>, Duration) solve(
    List<String> letters,
    String rawDic, {
    int gridSize = 4,
  }) {
    final sw = Stopwatch()..start();
    final solver = BoggleSolver._(gridSize);
    solver._loadAnagram(rawDic, letters.join());

    for (int i = 0; i < gridSize * gridSize; i++) {
      final visited = List.filled(gridSize * gridSize, false);
      visited[i] = true;
      solver._seekSoluce(letters, [i], letters[i], visited);
    }

    sw.stop();

    final words = solver._found.entries
        .map((e) => WordPath(word: e.key, path: e.value))
        .toList()
      ..sort((a, b) {
        final d = b.word.length.compareTo(a.word.length);
        return d != 0 ? d : a.word.compareTo(b.word);
      });

    return (words, sw.elapsed);
  }
}
