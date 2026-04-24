import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../widgets/cell.dart';

@Preview(name: 'Cellule seule')
Widget previewCell() => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Cell(initialLetter: 'A', focusNode: FocusNode()),
      ),
    ),
  ),
);
