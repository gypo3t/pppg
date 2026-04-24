import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/letter_pool.dart';
import '../models/app_settings.dart';
import '../models/nav_dir.dart';
import '../services/boggle_solver.dart';
import '../services/dictionary_service.dart';
import '../widgets/boggle_grid_widget.dart';
import '../widgets/menu_row.dart' show popItem;
import '../widgets/settings_dialog.dart';
import 'export_screen.dart';
import 'game_screen.dart';
import 'import_screen.dart';
import 'solver_screen.dart';

class EditionScreen extends StatefulWidget {
  final List<String>? initialLetters;
  final int? initialGridSize;

  const EditionScreen({super.key, this.initialLetters, this.initialGridSize});

  @override
  State<EditionScreen> createState() => _EditionScreenState();
}

class _EditionScreenState extends State<EditionScreen> {
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
  void dispose() {
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  void _navigate(int index, NavDir dir) {
    final row = index ~/ _gridSize;
    final next = switch (dir) {
      NavDir.left => index > 0 ? index - 1 : index,
      NavDir.right =>
        index < _gridSize * _gridSize - 1 ? index + 1 : index,
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
      _letters = generateGrid(_gridSize);
      _initNodes();
    });
  }

  Future<void> _openSettings() async {
    final result = await showSettingsDialog(context);
    if (result == null || !mounted) return;
    result.apply();
    if (result.gridSize != _gridSize) {
      setState(() {
        for (final fn in _focusNodes) {
          fn.dispose();
        }
        _gridSize = result.gridSize;
        _letters = generateGrid(_gridSize);
        _initNodes();
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _goToImport() async {
    final newLetters = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          expectedSize: _gridSize * _gridSize,
          gridN: _gridSize,
        ),
      ),
    );
    if (newLetters != null && mounted) {
      setState(() => _letters = newLetters);
    }
  }

  void _goToExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExportScreen(letters: _letters, gridSize: _gridSize),
      ),
    );
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
            Icon(Icons.grid_on_outlined, size: 18),
            SizedBox(width: 8),
            Text('Édition'),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.menu),
            itemBuilder: (_) => [
              popItem(Icons.sports_esports_outlined, 'Jouer avec cette grille', _goToGame),
              PopupMenuItem<void>(
                onTap: _solving ? null : _analyze,
                enabled: !_solving,
                height: 40,
                child: Row(
                  children: [
                    _solving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.list_alt_outlined, size: 18),
                    const SizedBox(width: 12),
                    const Text('Solutions', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              popItem(Icons.file_open_outlined, 'Importer', _goToImport),
              popItem(Icons.save_alt_outlined, 'Exporter', _goToExport),
              popItem(Icons.shuffle, 'Mélanger', _shuffle),
              const PopupMenuDivider(),
              popItem(Icons.settings_outlined, 'Paramètres', _openSettings),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Grid fills the smaller dimension, leaving room for buttons (~120px)
          final maxGridSize = min(
            constraints.maxWidth - 32,
            constraints.maxHeight - 120,
          ).clamp(80.0, 600.0);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _goToGame,
                        icon: const Icon(Icons.sports_esports),
                        label: const Text('Jouer avec cette grille'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _solving ? null : _analyze,
                        icon: _solving
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_solving ? 'Analyse…' : 'Analyser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
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
