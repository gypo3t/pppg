import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/letter_pool.dart';
import '../models/app_settings.dart';
import '../theme/app_colors.dart';
import '../models/session_stats.dart';
import 'stats_screen.dart';
import '../models/nav_dir.dart';
import '../services/boggle_solver.dart';
import '../services/dictionary_service.dart';
import '../route_observer.dart';
import '../widgets/boggle_app_bar.dart';
import '../widgets/boggle_grid_widget.dart';
import 'settings_screen.dart';
import 'game_screen.dart';
import 'solver_screen.dart';

class EditionScreen extends StatefulWidget {
  final List<String>? initialLetters;
  final int? initialGridSize;

  const EditionScreen({super.key, this.initialLetters, this.initialGridSize});

  @override
  State<EditionScreen> createState() => _EditionScreenState();
}

class _EditionScreenState extends State<EditionScreen> with RouteAware {
  late int _gridSize;
  late List<String> _letters;
  late List<FocusNode> _focusNodes;
  late List<UniqueKey> _cellKeys;
  bool _solving = false;

  @override
  void initState() {
    super.initState();
    _gridSize = widget.initialGridSize ?? AppSettings.gridSize;
    final init = widget.initialLetters;
    _letters = (init != null && init.length == _gridSize * _gridSize)
        ? List.of(init)
        : generateGrid(_gridSize);
    _initNodes();
  }

  void _initNodes() {
    _focusNodes = List.generate(_gridSize * _gridSize, (_) => FocusNode());
    _cellKeys = List.generate(_gridSize * _gridSize, (_) => UniqueKey());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    final newSize = AppSettings.gridSize;
    final last = SessionStats.lastLetters;

    if (newSize != _gridSize) {
      // Taille changée
      for (final fn in _focusNodes) fn.dispose();
      setState(() {
        _gridSize = newSize;
        _letters = (last != null && last.length == newSize * newSize)
            ? List.of(last) // lastLetters correspond à la nouvelle taille
            : generateGrid(newSize); // sinon on régénère
        _initNodes();
      });
    } else if (last != null && last.length == _gridSize * _gridSize) {
      // Taille identique, on restaure les lettres
      setState(() {
        _letters = List.of(last);
        _cellKeys = List.generate(_gridSize * _gridSize, (_) => UniqueKey());
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  void _navigate(int index, NavDir dir) {
    final row = index ~/ _gridSize;
    final next = switch (dir) {
      NavDir.left => index > 0 ? index - 1 : index,
      NavDir.right => index < _gridSize * _gridSize - 1 ? index + 1 : index,
      NavDir.up => row > 0 ? index - _gridSize : index,
      NavDir.down => row < _gridSize - 1 ? index + _gridSize : index,
    };
    _focusNodes[next].requestFocus();
  }

  void _onLetterChanged(int index, String letter) {
    _letters[index] = letter;
  }

  void _shuffle() {
    setState(() {
      for (final fn in _focusNodes) {
        fn.dispose();
      }
      _gridSize = AppSettings.gridSize;
      _letters = generateGrid(_gridSize);
      _initNodes();
    });
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    if (AppSettings.gridSize != _gridSize) {
      for (final fn in _focusNodes) {
        fn.dispose();
      }
      setState(() {
        _gridSize = AppSettings.gridSize;
        _letters = generateGrid(_gridSize);
        _initNodes();
      });
    } else {
      setState(() {});
    }
  }

  String get _gridContent {
    final n = _gridSize;
    return List.generate(
      n,
      (r) => _letters.sublist(r * n, r * n + n).join(),
    ).join('\n');
  }

  void _exportGridToClipboard() {
    Clipboard.setData(ClipboardData(text: _gridContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grille copiée dans le presse-papier')),
    );
  }

  Future<void> _importGridFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    final letters = text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .split('');
    final expected = _gridSize * _gridSize;
    if (letters.length < expected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pas assez de lettres (${letters.length}/$expected)'),
            backgroundColor: AppColors.errorMid,
          ),
        );
      }
      return;
    }
    setState(() => _letters = letters.sublist(0, expected));
  }

  Future<void> _analyze() async {
    if (!DictionaryService.loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement du dictionnaire…')),
      );
      return;
    }
    setState(() => _solving = true);
    final letters = List<String>.from(_letters);
    final gs = _gridSize;
    final (words, duration) = await Future(
      () => BoggleSolver.solve(letters, DictionaryService.raw, gridSize: gs),
    );
    if (!mounted) return;
    setState(() => _solving = false);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolverScreen(
          words: words,
          searchDuration: duration,
          letters: letters,
          gridSize: gs,
        ),
      ),
    );
  }

  void _goToGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          initialLetters: List.of(_letters),
          initialGridSize: _gridSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BoggleAppBar(
        activeScreen: BoggleScreen.edition,
        onGame: _goToGame,
        onStats: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatsScreen(
              words: SessionStats.lastWords,
              letters: SessionStats.lastLetters,
              gridSize: SessionStats.lastGridSize,
            ),
          ),
        ),
        onSettings: _openSettings,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          final maxGridSize = isLandscape
              ? (constraints.maxHeight - 32).clamp(80.0, 600.0)
              : (min(constraints.maxWidth, constraints.maxHeight) - 32).clamp(
                  80.0,
                  600.0,
                );

          final grid = Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox.square(
              dimension: maxGridSize,
              child: BoggleGridWidget(
                letters: _letters,
                gridSize: _gridSize,
                focusNodes: _focusNodes,
                cellKeys: _cellKeys,
                editable: true,
                onNavigate: _navigate,
                onLetterChanged: _onLetterChanged,
              ),
            ),
          );

          final buttons = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _goToGame,
                icon: const Icon(Icons.sports_esports),
                label: const Text('Jouer avec cette grille'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primaryBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _solving ? null : _analyze,
                icon: _solving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lightbulb_outline),
                label: Text(_solving ? 'Recherche…' : 'Solutions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primaryBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _shuffle,
                icon: const Icon(Icons.shuffle),
                label: const Text('Mélanger'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primaryBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _exportGridToClipboard,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Exporter (presse-papier)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primaryBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _importGridFromClipboard,
                icon: const Icon(Icons.paste_outlined),
                label: const Text('Importer (presse-papier)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primaryBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );

          if (isLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grille fixe à gauche
                grid,
                // Boutons dans une zone défilante à droite
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                    child: buttons,
                  ),
                ),
              ],
            );
          }

          // Portrait : mise en page originale
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: grid),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  child: Center(
                    child: SizedBox(width: maxGridSize, child: buttons),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
