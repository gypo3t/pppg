import 'dart:async';
import 'dart:math' show min, max;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constants/letter_pool.dart';
import '../models/app_settings.dart';
import '../models/session_stats.dart';
import '../models/word_path.dart';
import '../route_observer.dart';
import '../services/boggle_solver.dart';
import '../widgets/menu_row.dart' show popItem;
import '../services/dictionary_service.dart';
import '../widgets/boggle_app_bar.dart';
import '../widgets/boggle_grid_widget.dart';
import '../widgets/settings_dialog.dart';
import 'solver_screen.dart';

typedef _HistoryEntry = ({String word, bool valid, int score});

class GameScreen extends StatefulWidget {
  final List<String>? initialLetters;
  final int? initialGridSize;

  const GameScreen({super.key, this.initialLetters, this.initialGridSize});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with RouteAware {
  late int _gridSize;
  late List<String> _letters;
  List<WordPath> _words = [];
  bool _solved = false;
  bool _solving = false;
  Timer? _timer;
  late int _timerRemaining;
  bool _timerRunning = false;
  bool _gameOver = false;
  final Map<String, int> _playerFoundWords = {};
  int _playerScore = 0;
  final List<_HistoryEntry> _history = [];
  bool _statsRecorded = false;
  bool _pendingNavToSolver = false;
  bool _gameStarted = false;

  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  OverlayEntry? _toastEntry;

  late final _LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _gridSize = widget.initialGridSize ?? AppSettings.gridSize;
    final init = widget.initialLetters;
    _letters = (init != null && init.length == _gridSize * _gridSize)
        ? List.of(init)
        : generateGrid(_gridSize);
    _timerRemaining = AppSettings.gameDuration;
    _lifecycleObserver = _LifecycleObserver(
      onBackground: () {
        if (_gameInProgress) _pauseTimer();
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _gameStarted = true;
    _startGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  // Pause automatique quand un écran est empilé par-dessus.
  @override
  void didPushNext() {
    if (_gameInProgress) _pauseTimer();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _timer?.cancel();
    _toastEntry?.remove();
    _toastEntry = null;
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _recordStats();
    super.dispose();
  }

  bool get _gameInProgress => _timerRunning && !_gameOver;

  Future<bool> _confirmIfInProgress(String message) async {
    if (!(_gameStarted && !_gameOver)) return true;
    _pauseTimer();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partie en cours'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer la partie'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true && mounted && !_gameOver) _resumeTimer();
    return ok == true;
  }

  void _recordStats() {
    if (_statsRecorded) return;
    if (_playerFoundWords.isNotEmpty || _gameOver) {
      SessionStats.recordGame(
        playerWords: _playerFoundWords.length,
        solutionWords: _words.length,
      );
      _statsRecorded = true;
    }
  }

  void _startGame() {
    _timerRemaining = AppSettings.gameDuration;
    _timerRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timerRemaining--;
        if (_timerRemaining <= 0) {
          _timerRemaining = 0;
          _timerRunning = false;
          _gameOver = true;
          _timer?.cancel();
          _timer = null;
          _recordStats();
        }
      });
      if (_gameOver) _scheduleNavToSolver();
    });
    if (DictionaryService.loaded) {
      _solveBackground();
    } else {
      DictionaryService.load().then((_) {
        if (mounted) _solveBackground();
      });
    }
  }

  Future<void> _solveBackground() async {
    if (_solving || _solved) return;
    setState(() => _solving = true);
    final letters = List<String>.from(_letters);
    final gs = _gridSize;
    final (words, _) = await Future(
      () => BoggleSolver.solve(letters, DictionaryService.raw, gridSize: gs),
    );
    if (!mounted) return;
    setState(() {
      _words = words;
      _solved = true;
      _solving = false;
    });
    if (_pendingNavToSolver) _goToSolverAuto();
  }

  void _scheduleNavToSolver() {
    if (_pendingNavToSolver) return;
    _pendingNavToSolver = true;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _pendingNavToSolver) _goToSolverAuto();
    });
  }

  Future<void> _goToSolverAuto() async {
    if (!mounted || !_pendingNavToSolver || !_solved) return;
    _pendingNavToSolver = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolverScreen(
          words: _words,
          letters: _letters,
          gridSize: _gridSize,
          showFoundIndicators: true,
        ),
      ),
    );
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _timerRunning = false);
  }

  void _resumeTimer() {
    if (_timerRemaining <= 0 || _gameOver) return;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timerRemaining--;
        if (_timerRemaining <= 0) {
          _timerRemaining = 0;
          _timerRunning = false;
          _gameOver = true;
          _timer?.cancel();
          _timer = null;
          _recordStats();
        }
      });
      if (_gameOver) _scheduleNavToSolver();
    });
  }

  void _submitWord(String word) {
    word = word.trim().toUpperCase();
    _inputCtrl.clear();
    _inputFocus.requestFocus();
    if (word.length < 3) return;

    if (_playerFoundWords.containsKey(word)) {
      _showToast('Déjà joué !', Colors.orange.shade700);
      return;
    }

    if (!_solved) {
      _showToast('…', Colors.grey.shade600);
      return;
    }

    WordPath? match;
    for (final wp in _words) {
      if (wp.word == word) {
        match = wp;
        break;
      }
    }

    if (match == null) {
      setState(() => _history.insert(0, (word: word, valid: false, score: 0)));
      _showToast('Refusé', Colors.red.shade600);
      return;
    }

    final score = match.score;
    setState(() {
      _playerFoundWords[word] = score;
      _playerScore += score;
      match!.foundByPlayer = true;
      _history.insert(0, (word: word, valid: true, score: score));
    });
    _showToast('+$score pt${score > 1 ? 's' : ''}', Colors.green.shade600);
  }

  void _showToast(String text, Color color) {
    _toastEntry?.remove();
    final entry = OverlayEntry(
      builder: (_) => _Toast(text: text, color: color),
    );
    _toastEntry = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  Future<void> _newGame() async {
    if (!await _confirmIfInProgress('Abandonner la partie en cours ?')) return;
    _recordStats();
    _timer?.cancel();
    setState(() {
      _pendingNavToSolver = false;
      _gameStarted = true;
      _gridSize = AppSettings.gridSize;
      _letters = generateGrid(_gridSize);
      _words = [];
      _solved = false;
      _solving = false;
      _timerRemaining = AppSettings.gameDuration;
      _timerRunning = false;
      _gameOver = false;
      _playerFoundWords.clear();
      _playerScore = 0;
      _history.clear();
      _statsRecorded = false;
    });
    _startGame();
  }

  Future<void> _goToSolver() async {
    if (!await _confirmIfInProgress(
      'Interrompre la partie pour voir les solutions ?',
    )) {
      return;
    }
    _pauseTimer();
    if (!_solved) {
      if (!DictionaryService.loaded) {
        _showToast('Dico non chargé', Colors.grey.shade600);
        return;
      }
      await _solveBackground();
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolverScreen(
          words: _words,
          letters: _letters,
          gridSize: _gridSize,
          showFoundIndicators: true,
        ),
      ),
    );
    if (mounted && !_gameOver) _resumeTimer();
  }

  Future<void> _openSettings() async {
    _pauseTimer();
    final result = await showSettingsDialog(context);
    if (result != null) {
      result.apply();
      if (mounted) setState(() {});
    }
    if (mounted && !_gameOver) _resumeTimer();
  }

  Color get _timerColor {
    if (_timerRemaining <= 10) return Colors.red.shade600;
    if (_timerRemaining <= 30) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  String _formatTimer(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Accueil',
          onPressed: () {
            _recordStats();
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports_outlined, size: 18),
            SizedBox(width: 8),
            Text('Jeu'),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.menu),
            itemBuilder: (_) => [
              popItem(Icons.refresh, 'Nouvelle partie', () {
                _newGame();
              }),
              popItem(Icons.list_alt_outlined, 'Solutions', () {
                _goToSolver();
              }),
              const PopupMenuDivider(),
              popItem(Icons.settings_outlined, 'Paramètres', _openSettings),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isPortrait = constraints.maxWidth <= constraints.maxHeight;
          final gridSize = isPortrait
              ? min(
                  constraints.maxWidth - 32,
                  max(0.0, constraints.maxHeight - 112),
                )
              : max(0.0, constraints.maxHeight - 80);

          final gridWidget = Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox.square(
                dimension: gridSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BoggleGridWidget(
                      letters: _letters,
                      gridSize: _gridSize,
                      drawingEnabled: !_gameOver,
                      onPathCommit: _gameOver
                          ? null
                          : (word, _) => _submitWord(word),
                    ),
                    if (_gameStarted && !_timerRunning && !_gameOver)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _resumeTimer,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 52,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Pause',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );

          if (isPortrait) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderRow(),
                gridWidget,
                if (!_gameOver && AppSettings.showTextInput) _buildInputRow(),
                Expanded(child: _buildHistoryList()),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gridSize + 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildHeaderRow(), gridWidget],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_gameOver && AppSettings.showTextInput)
                        _buildInputRow(),
                      Expanded(child: _buildHistoryList()),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    final showMax = AppSettings.showMaxStats && _words.isNotEmpty;
    return BoggleHeaderRow(
      score: _playerScore,
      maxScore: showMax ? _words.fold<int>(0, (s, w) => s + w.score) : null,
      wordCount: _playerFoundWords.length,
      maxWordCount: showMax ? _words.length : null,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: _timerColor),
          const SizedBox(width: 4),
          Text(
            _formatTimer(_timerRemaining),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _timerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (_gameOver) ...[
            const SizedBox(width: 6),
            Text(
              '· Terminée',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (_timerRunning) ...[
            const SizedBox(width: 4),
            _timerBtn(icon: Icons.pause, onTap: _pauseTimer),
          ] else ...[
            const SizedBox(width: 4),
            _timerBtn(icon: Icons.play_arrow, onTap: _resumeTimer),
          ],
        ],
      ),
    );
  }

  Widget _timerBtn({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16),
        color: Colors.black45,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                TextInputFormatter.withFunction(
                  (_, v) => v.copyWith(text: v.text.toUpperCase()),
                ),
              ],
              decoration: InputDecoration(
                hintText: 'Proposer un mot…',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.orange.shade700,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: _submitWord,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _submitWord(_inputCtrl.text),
            icon: const Icon(Icons.check_circle_outline),
            color: Colors.orange.shade700,
            tooltip: 'Valider',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Center(
        child: Text(
          _gameOver ? 'Aucun mot soumis' : 'Proposez des mots…',
          style: const TextStyle(color: Colors.black38, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (ctx, i) {
        final entry = _history[i];
        return ListTile(
          dense: true,
          leading: Icon(
            entry.valid ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: entry.valid ? Colors.green.shade600 : Colors.red.shade400,
          ),
          title: Text(
            entry.word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: entry.valid ? Colors.green.shade700 : Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: entry.valid
              ? Text(
                  '+${entry.score} pt${entry.score > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : Text(
                  'refusé',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 11),
                ),
        );
      },
    );
  }
}

// ─── App-lifecycle observer ───────────────────────────────────────────────────

class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onBackground;
  _LifecycleObserver({required this.onBackground});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      onBackground();
    }
  }
}

// ─── Animated feedback toast ──────────────────────────────────────────────────

class _Toast extends StatefulWidget {
  final String text;
  final Color color;

  const _Toast({required this.text, required this.color});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_ctrl);
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
