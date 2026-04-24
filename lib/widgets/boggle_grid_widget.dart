import 'package:flutter/material.dart';
import '../models/nav_dir.dart';
import 'cell.dart';

class BoggleGridWidget extends StatefulWidget {
  final List<String> letters;
  final int gridSize;
  final List<FocusNode>? focusNodes;
  final List<UniqueKey>? cellKeys;
  final List<int>? highlightPath;
  final bool editable;
  final bool drawingEnabled;
  final void Function(int index, NavDir dir)? onNavigate;
  final void Function(int index, String letter)? onLetterChanged;
  final void Function(String word, List<int> path)? onPathCommit;

  const BoggleGridWidget({
    super.key,
    required this.letters,
    required this.gridSize,
    this.focusNodes,
    this.cellKeys,
    this.highlightPath,
    this.editable = false,
    this.drawingEnabled = false,
    this.onNavigate,
    this.onLetterChanged,
    this.onPathCommit,
  });

  @override
  State<BoggleGridWidget> createState() => _BoggleGridWidgetState();
}

class _BoggleGridWidgetState extends State<BoggleGridWidget> {
  List<FocusNode>? _ownedFocusNodes;
  late List<UniqueKey> _ownedCellKeys;
  List<int> _drawPath = [];

  @override
  void initState() {
    super.initState();
    if (widget.focusNodes == null) {
      _ownedFocusNodes = List.generate(
        widget.gridSize * widget.gridSize,
        (_) => FocusNode(),
      );
    }
    _ownedCellKeys = List.generate(
      widget.gridSize * widget.gridSize,
      (_) => UniqueKey(),
    );
  }

  @override
  void didUpdateWidget(BoggleGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gridSize != oldWidget.gridSize) {
      for (final fn in _ownedFocusNodes ?? []) {
        fn.dispose();
      }
      _ownedFocusNodes = widget.focusNodes == null
          ? List.generate(widget.gridSize * widget.gridSize, (_) => FocusNode())
          : null;
      _ownedCellKeys = List.generate(
        widget.gridSize * widget.gridSize,
        (_) => UniqueKey(),
      );
      _drawPath = [];
    }
  }

  @override
  void dispose() {
    for (final fn in _ownedFocusNodes ?? []) {
      fn.dispose();
    }
    super.dispose();
  }

  List<FocusNode> get _focusNodes => widget.focusNodes ?? _ownedFocusNodes!;
  List<UniqueKey> get _cellKeys => widget.cellKeys ?? _ownedCellKeys;

  int? _posToCell(Offset pos, double totalSize) {
    if (totalSize <= 0 ||
        pos.dx < 0 ||
        pos.dy < 0 ||
        pos.dx > totalSize ||
        pos.dy > totalSize) {
      return null;
    }
    final n = widget.gridSize;
    const sp = 8.0;
    final cs = (totalSize - (n - 1) * sp) / n;
    final stride = cs + sp;
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < n * n; i++) {
      final r = i ~/ n;
      final c = i % n;
      final dx = pos.dx - (c * stride + cs / 2);
      final dy = pos.dy - (r * stride + cs / 2);
      final d = dx * dx + dy * dy;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  Offset _gridCellCenter(int idx, double totalSize) {
    final n = widget.gridSize;
    const sp = 8.0;
    final cs = (totalSize - (n - 1) * sp) / n;
    final row = idx ~/ n;
    final col = idx % n;
    return Offset(col * (cs + sp) + cs / 2, row * (cs + sp) + cs / 2);
  }

  bool _isAdjacent(int a, int b) {
    final n = widget.gridSize;
    final ar = a ~/ n, ac = a % n;
    final br = b ~/ n, bc = b % n;
    return (ar - br).abs() <= 1 && (ac - bc).abs() <= 1 && a != b;
  }

  void _onPanStart(DragStartDetails details, double size) {
    final cell = _posToCell(details.localPosition, size);
    if (cell != null) setState(() => _drawPath = [cell]);
  }

  // Each cell has a circular activation zone (radius = 40 % of cell size).
  // A neighbor is committed only when the finger physically enters its circle.
  // Because circles never overlap (gap between adjacent circles ≈ 20 % of
  // cell size + spacing), a straight diagonal drag cannot accidentally
  // activate an orthogonal cell that lies between start and target.
  void _onPanUpdate(DragUpdateDetails details, double size) {
    if (_drawPath.isEmpty) return;
    final cursor = details.localPosition;

    final n = widget.gridSize;
    const sp = 8.0;
    final cs = (size - (n - 1) * sp) / n;
    final r2 = (cs * 0.4) * (cs * 0.4);

    for (int i = 0; i < n * n; i++) {
      final center = _gridCellCenter(i, size);
      final dx = cursor.dx - center.dx;
      final dy = cursor.dy - center.dy;
      if (dx * dx + dy * dy > r2) continue;

      // Cursor is inside cell i's activation circle.
      if (_drawPath.length >= 2 && i == _drawPath[_drawPath.length - 2]) {
        setState(() => _drawPath.removeLast()); // backtrack
        return;
      }
      if (_drawPath.contains(i)) return; // already in path, nothing to do
      if (!_isAdjacent(_drawPath.last, i)) return; // non-adjacent, ignore
      setState(() => _drawPath.add(i));
      return;
    }
  }

  void _onPanEnd(DragEndDetails _) {
    final path = List<int>.from(_drawPath);
    setState(() => _drawPath = []);
    if (path.length >= 3) {
      final word = path.map((i) => widget.letters[i]).join();
      widget.onPathCommit?.call(word, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = constraints.maxWidth;
        final activePath =
            widget.drawingEnabled
                ? _drawPath
                : (widget.highlightPath ?? const <int>[]);

        Widget grid = GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridSize,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.gridSize * widget.gridSize,
          itemBuilder: (ctx, index) {
            final stepIdx = activePath.indexOf(index);
            final cell = Cell(
              key: _cellKeys[index],
              initialLetter: widget.letters[index],
              focusNode: _focusNodes[index],
              onNavigate:
                  widget.editable
                      ? (dir) => widget.onNavigate?.call(index, dir)
                      : null,
              onLetterChanged:
                  widget.editable
                      ? (ch) => widget.onLetterChanged?.call(index, ch)
                      : null,
              highlightStep: stepIdx >= 0 ? stepIdx : null,
              dimmed: false,
            );
            // Non-editable, non-drawing: cells are purely decorative.
            return (widget.drawingEnabled || !widget.editable)
                ? IgnorePointer(child: cell)
                : cell;
          },
        );

        if (widget.drawingEnabled) {
          grid = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            child: grid,
          );
        }

        return Stack(
          children: [
            grid,
            if (activePath.length >= 2)
              IgnorePointer(
                child: CustomPaint(
                  painter: BogglePathPainter(
                    path: activePath,
                    gridSize: size,
                    gridN: widget.gridSize,
                  ),
                  size: Size(size, size),
                ),
              ),
          ],
        );
      },
    );
  }
}

class BogglePathPainter extends CustomPainter {
  final List<int> path;
  final double gridSize;
  final int gridN;
  static const double _spacing = 8.0;

  const BogglePathPainter({
    required this.path,
    required this.gridSize,
    required this.gridN,
  });

  Offset _cellCenter(int idx) {
    final cellSize = (gridSize - (gridN - 1) * _spacing) / gridN;
    final row = idx ~/ gridN;
    final col = idx % gridN;
    return Offset(
      col * (cellSize + _spacing) + cellSize / 2,
      row * (cellSize + _spacing) + cellSize / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final cellSize = (gridSize - (gridN - 1) * _spacing) / gridN;
    final inset = cellSize * 0.30;
    final centers = path.map(_cellCenter).toList();

    final startDir = centers[1] - centers[0];
    final startUnit = startDir / startDir.distance;
    final startPt = centers.first + startUnit * inset;

    final endDir = centers.last - centers[centers.length - 2];
    final endUnit = endDir / endDir.distance;
    final arrowTip = centers.last - endUnit * inset;

    const arrowLen = 11.0;
    const arrowHalfWidth = 5.5;
    final arrowBase = arrowTip - endUnit * arrowLen;

    final color = Colors.orange.shade700.withValues(alpha: 0.85);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final waypoints = <Offset>[
      startPt,
      ...centers.sublist(1, centers.length - 1),
      arrowBase,
    ];

    final curve = Path()..moveTo(waypoints.first.dx, waypoints.first.dy);
    if (waypoints.length == 2) {
      curve.lineTo(waypoints.last.dx, waypoints.last.dy);
    } else {
      final mid = (waypoints[0] + waypoints[1]) / 2;
      curve.lineTo(mid.dx, mid.dy);
      for (int i = 1; i < waypoints.length - 2; i++) {
        final nextMid = (waypoints[i] + waypoints[i + 1]) / 2;
        curve.quadraticBezierTo(
          waypoints[i].dx, waypoints[i].dy,
          nextMid.dx, nextMid.dy,
        );
      }
      curve.quadraticBezierTo(
        waypoints[waypoints.length - 2].dx,
        waypoints[waypoints.length - 2].dy,
        waypoints.last.dx,
        waypoints.last.dy,
      );
    }
    canvas.drawPath(curve, linePaint);

    final perp = Offset(-endUnit.dy, endUnit.dx);
    final arrowPath =
        Path()
          ..moveTo(arrowTip.dx, arrowTip.dy)
          ..lineTo(
            (arrowBase + perp * arrowHalfWidth).dx,
            (arrowBase + perp * arrowHalfWidth).dy,
          )
          ..lineTo(
            (arrowBase - perp * arrowHalfWidth).dx,
            (arrowBase - perp * arrowHalfWidth).dy,
          )
          ..close();
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      startPt,
      4.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(BogglePathPainter old) =>
      old.path != path || old.gridSize != gridSize || old.gridN != gridN;
}
