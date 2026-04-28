import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../models/nav_dir.dart';

class Cell extends StatefulWidget {
  final String initialLetter;
  final FocusNode focusNode;
  final void Function(NavDir dir)? onNavigate;
  final void Function(String letter)? onLetterChanged;
  final int? highlightStep;
  final bool dimmed;
  final bool blurLetter;

  const Cell({
    super.key,
    required this.initialLetter,
    required this.focusNode,
    this.onNavigate,
    this.onLetterChanged,
    this.highlightStep,
    this.dimmed = false,
    this.blurLetter = false,
  });

  @override
  State<Cell> createState() => _CellState();
}

class _CellState extends State<Cell> {
  late String _letter;
  final _inputCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _letter = widget.initialLetter.toUpperCase();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(Cell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLetter != oldWidget.initialLetter) {
      setState(() => _letter = widget.initialLetter.toUpperCase());
    }
  }

  void _onFocusChange() {
    setState(() => _editing = widget.focusNode.hasFocus);
  }

  void _onInput(String value) {
    if (value.isEmpty) return;
    final char = value[value.length - 1].toUpperCase();
    _inputCtrl.clear();
    if (!RegExp(r'[A-Z]').hasMatch(char)) return;
    setState(() => _letter = char);
    widget.onLetterChanged?.call(char);
    widget.onNavigate?.call(NavDir.right);
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final dir = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => NavDir.left,
      LogicalKeyboardKey.arrowRight => NavDir.right,
      LogicalKeyboardKey.arrowUp => NavDir.up,
      LogicalKeyboardKey.arrowDown => NavDir.down,
      _ => null,
    };
    if (dir == null) return KeyEventResult.ignored;
    widget.onNavigate?.call(dir);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _inputCtrl.dispose();
    super.dispose();
  }

  BoxDecoration _dieDecoration(double radius) {
    if (_editing) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cellEditGradStart, AppColors.cellEditGradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cellEditBorder.withValues(alpha: 0.55),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.cellEditBorder, width: 2.5),
      );
    }
    if (widget.highlightStep != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cellGradientStart, AppColors.cellGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: AppColors.primary, width: 2.5),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.cellNormalGradStart, AppColors.cellNormalGradEnd],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          offset: const Offset(2, 3),
          blurRadius: 5,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.9),
          offset: const Offset(-1, -1),
          blurRadius: 2,
        ),
      ],
      border: Border.all(color: AppColors.cellNormalBorder, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight;
        final radius = size * 0.15;

        final badgeSize = size * 0.28;
        return Opacity(
          opacity: widget.dimmed ? 0.35 : 1.0,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: _handleKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: widget.focusNode,
                      textCapitalization: TextCapitalization.characters,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onChanged: _onInput,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.focusNode.requestFocus(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: _dieDecoration(radius),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.1),
                      child: ImageFiltered(
                        imageFilter: widget.blurLetter
                            ? ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                                tileMode: TileMode.decal,
                              )
                            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _letter,
                            style: TextStyle(
                              fontSize: 999,
                              fontWeight: FontWeight.bold,
                              color: _editing
                                  ? AppColors.cellEditingText
                                  : widget.highlightStep != null
                                  ? AppColors.primaryDark
                                  : AppColors.cellNormalText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.highlightStep != null)
                  Positioned(
                    top: size * 0.06,
                    right: size * 0.06,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.highlightStep! + 1}',
                        style: TextStyle(
                          fontSize: badgeSize * 0.6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
