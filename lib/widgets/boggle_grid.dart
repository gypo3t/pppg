import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/letter_pool.dart';
import '../models/nav_dir.dart';
import '../models/word_path.dart';
import '../services/boggle_solver.dart';
import 'cell.dart';

class BoggleGrid extends StatefulWidget {
  const BoggleGrid({super.key});

  @override
  State<BoggleGrid> createState() => _BoggleGridState();
}

class _BoggleGridState extends State<BoggleGrid> {
  static const int _size = 4;
  static const double _itemHeight = 44.0;

  List<String> _letters = generateGrid(_size);
  final _focusNodes = List.generate(_size * _size, (_) => FocusNode());
  List<UniqueKey> _keys = List.generate(_size * _size, (_) => UniqueKey());

  Set<String> _dictionary = {};
  bool _dictionaryLoaded = false;
  List<WordPath> _words = [];

  final _selectedIndex = ValueNotifier<int>(0);
  late final FixedExtentScrollController _wheelCtrl;
  
  @override
  void initState() {
    super.initState();
    _wheelCtrl = FixedExtentScrollController();
    _loadDictionary();
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    _wheelCtrl.dispose();
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDictionary() async {
    final text = await rootBundle.loadString('assets/words.txt');
    _dictionary = text
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length >= 3)
        .toSet();
    if (!mounted) return;
    setState(() => _dictionaryLoaded = true);
    _computeWords();
  }

  void _computeWords() {
    final words = BoggleSolver.solve(_letters, _dictionary);
    setState(() => _words = words);
    _selectedIndex.value = 0;
    if (_wheelCtrl.hasClients) _wheelCtrl.jumpToItem(0);
  }

  void _shuffle() {
    setState(() {
      _letters = generateGrid(_size);
      _keys = List.generate(_size * _size, (_) => UniqueKey());
      _words = [];
    });
    _selectedIndex.value = 0;
    if (_dictionaryLoaded) _computeWords();
  }

  void _navigate(int index, NavDir dir) {
    final row = index ~/ _size;
    final int next = switch (dir) {
      NavDir.left => index > 0 ? index - 1 : index,
      NavDir.right => index < _size * _size - 1 ? index + 1 : index,
      NavDir.up => row > 0 ? index - _size : index,
      NavDir.down => row < _size - 1 ? index + _size : index,
    };
    _focusNodes[next].requestFocus();
  }

  Widget _buildGrid(double gridSize) {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, sel, _) {
        final path = _words.isNotEmpty ? _words[sel].path : const <int>[];
        return Stack(
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _size,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _size * _size,
              itemBuilder: (context, index) {
                final stepIdx = path.indexOf(index);
                return Cell(
                  key: _keys[index],
                  initialLetter: _letters[index],
                  focusNode: _focusNodes[index],
                  onNavigate: (dir) => _navigate(index, dir),
                  highlightStep: stepIdx >= 0 ? stepIdx : null,
                );
              },
            ),
            if (path.length >= 2)
              IgnorePointer(
                child: CustomPaint(
                  painter: _PathArrowPainter(path: path, gridSize: gridSize),
                  size: Size(gridSize, gridSize),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWordList() {
    if (!_dictionaryLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_words.isEmpty) {
      return const Center(
        child: Text(
          'Aucun mot trouvé',
          style: TextStyle(color: Colors.black38),
        ),
      );
    }
    return Stack(
      children: [
        // Rectangle de sélection fixe au centre — ne bouge jamais
        Align(
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Container(
              height: _itemHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.orange.shade300),
                ),
              ),
            ),
          ),
        ),
        // Roue de mots — item sélectionné toujours centré nativement
        ListWheelScrollView.useDelegate(
          controller: _wheelCtrl,
          itemExtent: _itemHeight,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 100,
          perspective: 0.0001,
          onSelectedItemChanged: (i) => _selectedIndex.value = i,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: _words.length,
            builder: (context, i) {
              return ValueListenableBuilder<int>(
                valueListenable: _selectedIndex,
                builder: (context, sel, _) {
                  final selected = i == sel;
                  return Center(
                    child: Text(
                      _words[i].word,
                      style: TextStyle(
                        fontSize: selected ? 18 : 15,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? Colors.orange.shade800
                            : Colors.black45,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boggle'),
        actions: [
          IconButton(icon: const Icon(Icons.shuffle), onPressed: _shuffle),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxWidth <= constraints.maxHeight;
          if (isPortrait) {
            final gridSize = max(0.0, constraints.maxWidth - 48);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox.square(
                    dimension: gridSize,
                    child: _buildGrid(gridSize),
                  ),
                ),
                Expanded(child: _buildWordList()),
              ],
            );
          } else {
            final gridSize = max(0.0, constraints.maxHeight - 48);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox.square(
                    dimension: gridSize,
                    child: _buildGrid(gridSize),
                  ),
                ),
                Expanded(child: _buildWordList()),
              ],
            );
          }
        },
      ),
    );
  }
}

class _PathArrowPainter extends CustomPainter {
  final List<int> path;
  final double gridSize;
  static const int _n = 4;
  static const double _spacing = 8.0;

  const _PathArrowPainter({required this.path, required this.gridSize});

  Offset _cellCenter(int idx) {
    final cellSize = (gridSize - (_n - 1) * _spacing) / _n;
    final row = idx ~/ _n;
    final col = idx % _n;
    return Offset(
      col * (cellSize + _spacing) + cellSize / 2,
      row * (cellSize + _spacing) + cellSize / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final cellSize = (gridSize - (_n - 1) * _spacing) / _n;
    final inset = cellSize * 0.33;
    final centers = path.map(_cellCenter).toList();

    final startDir = centers[1] - centers[0];
    final startUnit = startDir / startDir.distance;
    final startPt = centers.first + startUnit * inset;

    final endDir = centers.last - centers[centers.length - 2];
    final endUnit = endDir / endDir.distance;
    final endPt = centers.last - endUnit * inset;

    final linePaint = Paint()
      ..color = Colors.orange.shade700.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Polyligne continue
    final polyline = Path()..moveTo(startPt.dx, startPt.dy);
    for (int i = 1; i < centers.length - 1; i++) {
      polyline.lineTo(centers[i].dx, centers[i].dy);
    }
    polyline.lineTo(endPt.dx, endPt.dy);
    canvas.drawPath(polyline, linePaint);

    // Tête de flèche unique à la fin
    final angle = atan2(endDir.dy, endDir.dx);
    const arrowLen = 12.0;
    const arrowAngle = 0.45;
    final tip = Path()
      ..moveTo(endPt.dx, endPt.dy)
      ..lineTo(
        endPt.dx - arrowLen * cos(angle - arrowAngle),
        endPt.dy - arrowLen * sin(angle - arrowAngle),
      )
      ..moveTo(endPt.dx, endPt.dy)
      ..lineTo(
        endPt.dx - arrowLen * cos(angle + arrowAngle),
        endPt.dy - arrowLen * sin(angle + arrowAngle),
      );
    canvas.drawPath(tip, linePaint);

    // Point de départ
    canvas.drawCircle(
      startPt,
      4.0,
      Paint()
        ..color = Colors.orange.shade700.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PathArrowPainter old) =>
      old.path != path || old.gridSize != gridSize;
}
