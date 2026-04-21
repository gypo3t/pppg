import '../models/word_path.dart';

class BoggleSolver {
  static const _size = 4;

  static final _adjacency = () {
    final adj = List.generate(_size * _size, (i) {
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
    return adj;
  }();

  static List<WordPath> solve(List<String> letters, Set<String> dictionary) {
    final results = <String, WordPath>{};
    final visited = List.filled(_size * _size, false);
    final path = <int>[];

    void dfs(int idx, String word) {
      if (word.length >= 3 && dictionary.contains(word) && !results.containsKey(word)) {
        results[word] = WordPath(word: word, path: List.of(path));
      }
      if (word.length >= 8) return;
      for (final n in _adjacency[idx]) {
        if (!visited[n]) {
          visited[n] = true;
          path.add(n);
          dfs(n, word + letters[n]);
          path.removeLast();
          visited[n] = false;
        }
      }
    }

    for (int i = 0; i < _size * _size; i++) {
      visited[i] = true;
      path.add(i);
      dfs(i, letters[i]);
      path.removeLast();
      visited[i] = false;
    }

    return results.values.toList()
      ..sort((a, b) {
        final d = b.word.length.compareTo(a.word.length);
        return d != 0 ? d : a.word.compareTo(b.word);
      });
  }
}
