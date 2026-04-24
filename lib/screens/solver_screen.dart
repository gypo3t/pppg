import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import '../models/word_path.dart';
import '../widgets/boggle_app_bar.dart';
import '../widgets/boggle_grid_widget.dart';
import '../widgets/menu_row.dart' show popItem;
import '../widgets/settings_dialog.dart';
import 'edition_screen.dart';
import 'export_screen.dart';
import 'game_screen.dart';

enum _SortMode { score, alpha, length }

class SolverScreen extends StatefulWidget {
  final List<WordPath> words;
  final Duration? searchDuration;
  final List<String> letters;
  final int gridSize;
  final bool showFoundIndicators;

  const SolverScreen({
    super.key,
    required this.words,
    required this.letters,
    required this.gridSize,
    this.searchDuration,
    this.showFoundIndicators = false,
  });

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  _SortMode _sortMode = _SortMode.score;
  String? _selectedWord;

  List<WordPath> get _sorted {
    final list = List<WordPath>.from(widget.words);
    switch (_sortMode) {
      case _SortMode.score:
        list.sort((a, b) {
          final d = b.score.compareTo(a.score);
          return d != 0 ? d : a.word.compareTo(b.word);
        });
      case _SortMode.alpha:
        list.sort((a, b) => a.word.compareTo(b.word));
      case _SortMode.length:
        list.sort((a, b) {
          final d = b.word.length.compareTo(a.word.length);
          return d != 0 ? d : a.word.compareTo(b.word);
        });
    }
    return list;
  }

  WordPath? get _selectedPath {
    if (_selectedWord == null) return null;
    try {
      return widget.words.firstWhere((w) => w.word == _selectedWord);
    } catch (_) {
      return null;
    }
  }


  Widget _buildHeaderRow() {
    final maxScore = widget.words.fold<int>(0, (s, w) => s + w.score);
    final maxWordCount = widget.words.length;
    final found = widget.words.where((w) => w.foundByPlayer).toList();
    final playerScore = found.fold<int>(0, (s, w) => s + w.score);

    return BoggleHeaderRow(
      score: widget.showFoundIndicators ? playerScore : maxScore,
      maxScore: widget.showFoundIndicators ? maxScore : null,
      wordCount: widget.showFoundIndicators ? found.length : maxWordCount,
      maxWordCount: widget.showFoundIndicators ? maxWordCount : null,
      leading: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              initialLetters: widget.letters,
              initialGridSize: widget.gridSize,
            ),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 15, color: Colors.black45),
            SizedBox(width: 4),
            Text(
              'Nouvelle partie',
              style: TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final result = await showSettingsDialog(context);
    if (result != null) {
      result.apply();
      if (mounted) setState(() {});
    }
  }

  void _showFullStats() {
    final byLength = <int, List<WordPath>>{};
    for (final wp in widget.words) {
      (byLength[wp.word.length] ??= []).add(wp);
    }
    final keys = byLength.keys.toList()..sort();
    final totalScore = widget.words.fold(0, (s, w) => s + w.score);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Statistiques complètes'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final len in keys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$len lettres',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text('${byLength[len]!.length} mot(s)'),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Text(
                    'Score total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '$totalScore pts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Accueil',
          onPressed: () =>
              Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined, size: 18),
            SizedBox(width: 8),
            Text('Solutions'),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.menu),
            itemBuilder: (_) => [
              popItem(Icons.bar_chart_outlined, 'Statistiques',
                  widget.words.isNotEmpty ? _showFullStats : null,
                  enabled: widget.words.isNotEmpty),
              const PopupMenuDivider(),
              popItem(Icons.sports_esports_outlined, 'Jouer avec cette grille', () =>
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GameScreen(
                      initialLetters: widget.letters,
                      initialGridSize: widget.gridSize,
                    ),
                  ))),
              popItem(Icons.grid_on_outlined, 'Éditer', () =>
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EditionScreen(
                      initialLetters: widget.letters,
                      initialGridSize: widget.gridSize,
                    ),
                  ))),
              popItem(Icons.upload_file_outlined, 'Exporter', () =>
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ExportScreen(
                      letters: widget.letters,
                      gridSize: widget.gridSize,
                    ),
                  ))),
              const PopupMenuDivider(),
              popItem(Icons.settings_outlined, 'Paramètres', _openSettings),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isPortrait = constraints.maxWidth <= constraints.maxHeight;
          final gridDisplaySize = isPortrait
              ? min(
                  constraints.maxWidth - 32,
                  max(0.0, constraints.maxHeight - 112),
                )
              : max(0.0, constraints.maxHeight - 80);

          final gridWidget = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox.square(
              dimension: gridDisplaySize,
              child: BoggleGridWidget(
                letters: widget.letters,
                gridSize: widget.gridSize,
                highlightPath: _selectedPath?.path,
              ),
            ),
          );

          final wordPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Tri :',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Score',
                      selected: _sortMode == _SortMode.score,
                      onTap: () =>
                          setState(() => _sortMode = _SortMode.score),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'Alpha',
                      selected: _sortMode == _SortMode.alpha,
                      onTap: () =>
                          setState(() => _sortMode = _SortMode.alpha),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'Lettres',
                      selected: _sortMode == _SortMode.length,
                      onTap: () =>
                          setState(() => _sortMode = _SortMode.length),
                    ),
                  ],
                ),
              ),
              const Divider(height: 4),
              Expanded(
                child: widget.words.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun mot trouvé',
                          style: TextStyle(color: Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _sorted.length,
                        itemBuilder: (ctx, i) {
                          final wp = _sorted[i];
                          final sel = wp.word == _selectedWord;
                          return _WordTile(
                            wordPath: wp,
                            selected: sel,
                            showFoundIndicator: widget.showFoundIndicators,
                            onTap: () => setState(
                              () => _selectedWord = sel ? null : wp.word,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );

          if (isPortrait) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderRow(),
                Align(alignment: Alignment.topCenter, child: gridWidget),
                Expanded(child: wordPanel),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gridDisplaySize + 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildHeaderRow(), gridWidget],
                  ),
                ),
                Expanded(child: wordPanel),
              ],
            );
          }
        },
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final WordPath wordPath;
  final bool selected;
  final bool showFoundIndicator;
  final VoidCallback onTap;

  const _WordTile({
    required this.wordPath,
    required this.selected,
    required this.showFoundIndicator,
    required this.onTap,
  });

  Color _scoreColor(int score) => switch (score) {
        1 => Colors.blueGrey.shade400,
        2 => Colors.blue.shade500,
        3 => Colors.teal.shade500,
        5 => Colors.orange.shade600,
        _ => Colors.red.shade600,
      };

  @override
  Widget build(BuildContext context) {
    final score = wordPath.score;
    final found = wordPath.foundByPlayer;
    return Material(
      color: selected
          ? Colors.orange.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _scoreColor(score),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wordPath.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: selected ? 15 : 14,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected
                        ? Colors.orange.shade800
                        : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${wordPath.word.length}L',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                ),
              ),
              if (showFoundIndicator) ...[
                const SizedBox(width: 8),
                Icon(
                  found
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: found ? Colors.green.shade600 : Colors.black12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
