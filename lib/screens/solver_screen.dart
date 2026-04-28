import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../models/word_path.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/boggle_app_bar.dart';
import '../widgets/boggle_grid_widget.dart';
import 'settings_screen.dart';
import 'game_screen.dart';
import 'stats_screen.dart';

enum _SortMode { score, alpha, length }

enum _FilterMode { all, player }

class SolverScreen extends StatefulWidget {
  final List<WordPath> words;
  final Duration? searchDuration;
  final List<String> letters;
  final int gridSize;
  final bool showFoundIndicators;
  final bool hasGameBelow;

  const SolverScreen({
    super.key,
    required this.words,
    required this.letters,
    required this.gridSize,
    this.searchDuration,
    this.showFoundIndicators = false,
    this.hasGameBelow = false,
  });

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  _SortMode _sortMode = _SortMode.score;
  _FilterMode _filterMode = _FilterMode.all;
  String? _selectedWord;

  List<WordPath> get _sorted {
    final source = _filterMode == _FilterMode.player
        ? widget.words.where((w) => w.foundByPlayer).toList()
        : List<WordPath>.from(widget.words);
    switch (_sortMode) {
      case _SortMode.score:
        source.sort((a, b) {
          final d = b.score.compareTo(a.score);
          return d != 0 ? d : a.word.compareTo(b.word);
        });
      case _SortMode.alpha:
        source.sort((a, b) => a.word.compareTo(b.word));
      case _SortMode.length:
        source.sort((a, b) {
          final d = b.word.length.compareTo(a.word.length);
          return d != 0 ? d : a.word.compareTo(b.word);
        });
    }
    return source;
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
      trailing: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.copy_outlined, size: 18),
        color: AppColors.black45,
        onPressed: widget.words.isNotEmpty ? _exportToClipboard : null,
      ),

      leading: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.refresh, size: 18),
        color: AppColors.black45,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              initialLetters: null,
              initialGridSize: AppSettings.gridSize,
            ),
          ),
        ),
      ),
    );
  }

  void _exportToClipboard() {
    final n = widget.gridSize;
    final gridRows = List.generate(
      n,
      (r) => widget.letters.sublist(r * n, r * n + n).join(),
    ).join('\n');

    final sorted = List<WordPath>.from(widget.words)
      ..sort((a, b) {
        final d = b.score.compareTo(a.score);
        return d != 0 ? d : a.word.compareTo(b.word);
      });
    final totalScore = widget.words.fold<int>(0, (s, w) => s + w.score);

    final buf = StringBuffer()
      ..writeln(gridRows)
      ..writeln()
      ..writeln(
        '--- Solutions (${widget.words.length} mots, $totalScore pts) ---',
      );
    for (final w in sorted) {
      buf.writeln('${w.word} (${w.score} pt${w.score > 1 ? 's' : ''})');
    }

    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grille et solutions copiées dans le presse-papier'),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: BoggleAppBar(
        activeScreen: BoggleScreen.solver,
        onGame: widget.hasGameBelow
            ? () => Navigator.of(context).pop()
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    initialLetters: widget.letters,
                    initialGridSize: widget.gridSize,
                  ),
                ),
              ),
        onEdition: () => Navigator.of(context).popUntil((r) => r.isFirst),
        onStats: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatsScreen(
              words: widget.words,
              letters: widget.letters,
              gridSize: widget.gridSize,
              hasGameBelow: widget.hasGameBelow,
            ),
          ),
        ),
        onSettings: _openSettings,
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isPortrait = constraints.maxWidth <= constraints.maxHeight;
          final gridDisplaySize = max(
            0.0,
            min(constraints.maxWidth - 32, constraints.maxHeight - 64),
          );

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
                    _Chip(
                      label: 'Toutes',
                      selected: _filterMode == _FilterMode.all,
                      onTap: () => setState(() {
                        _filterMode = _FilterMode.all;
                        _selectedWord = null;
                      }),
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      label: 'Joueur',
                      selected: _filterMode == _FilterMode.player,
                      onTap: () => setState(() {
                        _filterMode = _FilterMode.player;
                        _selectedWord = null;
                      }),
                    ),
                    const Spacer(),
                    PopupMenuButton<_SortMode>(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      tooltip: 'Trier',
                      onSelected: (mode) => setState(() => _sortMode = mode),
                      itemBuilder: (_) => [
                        CheckedPopupMenuItem(
                          value: _SortMode.score,
                          checked: _sortMode == _SortMode.score,
                          child: const Text('Score'),
                        ),
                        CheckedPopupMenuItem(
                          value: _SortMode.alpha,
                          checked: _sortMode == _SortMode.alpha,
                          child: const Text('Alphabétique'),
                        ),
                        CheckedPopupMenuItem(
                          value: _SortMode.length,
                          checked: _sortMode == _SortMode.length,
                          child: const Text('Longueur'),
                        ),
                      ],
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
                          style: TextStyle(color: AppColors.black38),
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

          final wordCard = Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Align(
              alignment: isPortrait ? Alignment.topCenter : Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppCard.maxWidth),
                child: AppCard.card(child: wordPanel),
              ),
            ),
          );

          final gridColumn = SizedBox(
            width: gridDisplaySize + 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildHeaderRow(), gridWidget],
            ),
          );

          if (isPortrait) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.topCenter, child: gridColumn),
                Expanded(child: wordCard),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                gridColumn,
                Expanded(child: wordCard),
              ],
            );
          }
        },
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
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
          color: selected ? AppColors.primary : AppColors.grey200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : AppColors.black54,
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
    1 => AppColors.score1,
    2 => AppColors.score2,
    3 => AppColors.score3,
    5 => AppColors.score5,
    _ => AppColors.scoreMax,
  };

  @override
  Widget build(BuildContext context) {
    final score = wordPath.score;
    final found = wordPath.foundByPlayer;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
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
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? AppColors.primaryDark : AppColors.black87,
                  ),
                ),
              ),
              Text(
                '${wordPath.word.length}L',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(fontSize: 11, color: AppColors.black38),
              ),
              if (showFoundIndicator) ...[
                const SizedBox(width: 8),
                Icon(
                  found ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: found ? AppColors.success : AppColors.black12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
