import 'package:flutter/material.dart';
import 'constants.dart';
import 'values.dart';

class Piece {
  Tetromino type;
  List<List<int>> shape;

  Piece({required this.type}) : shape = [];

  void initializePiece() {
    // Get the shape from TetrominoValues
    shape = TetrominoValues.shapes[type] ?? [];
  }

  Color get color {
    return TetrominoValues.colors[type] ?? Colors.grey;
  }

  List<List<int>> getShape() {
    return shape;
  }
}