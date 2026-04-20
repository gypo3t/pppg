import 'package:flutter/material.dart';
import '../constants/letter_pool.dart';
import '../models/nav_dir.dart';
import 'cell.dart';

class BoggleGrid extends StatefulWidget {
  const BoggleGrid({super.key});

  @override
  State<BoggleGrid> createState() => _BoggleGridState();
}

class _BoggleGridState extends State<BoggleGrid> {
  static const int _size = 4;
  List<String> _letters = generateGrid(_size);
  final _focusNodes = List.generate(_size * _size, (_) => FocusNode());
  List<UniqueKey> _keys = List.generate(_size * _size, (_) => UniqueKey());

  void _shuffle() {
    setState(() {
      _letters = generateGrid(_size);
      _keys = List.generate(_size * _size, (_) => UniqueKey());
    });
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
          final gridSize =
              constraints.maxWidth.clamp(0.0, constraints.maxHeight) - 48;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: gridSize,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _size,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _size * _size,
                      itemBuilder: (context, index) {
                        return Cell(
                          key: _keys[index],
                          initialLetter: _letters[index],
                          focusNode: _focusNodes[index],
                          onNavigate: (dir) => _navigate(index, dir),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
