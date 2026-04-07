import 'package:flutter/material.dart';

enum Tetromino {
  I,
  J,
  L,
  O,
  S,
  T,
  Z,
}

class TetrominoValues {
  static const Map<Tetromino, Color> colors = {
    Tetromino.I: Colors.cyanAccent,
    Tetromino.J: Colors.purpleAccent,
    Tetromino.L: Colors.orangeAccent,
    Tetromino.O: Colors.yellowAccent,
    Tetromino.S: Colors.greenAccent,
    Tetromino.T: Colors.pinkAccent,
    Tetromino.Z: Colors.redAccent,
  };

  static const Map<Tetromino, List<List<int>>> shapes = {
    Tetromino.I: [[0, 0], [1, 0], [2, 0], [3, 0]], // Horizontal line (4x1)
    Tetromino.J: [[0, 0], [0, 1], [1, 1], [2, 1]], // J shape (3x2)
    Tetromino.L: [[2, 0], [0, 1], [1, 1], [2, 1]], // L shape (3x2)
    Tetromino.O: [[0, 0], [1, 0], [0, 1], [1, 1]], // Square (2x2)
    Tetromino.S: [[1, 0], [2, 0], [0, 1], [1, 1]], // S shape (3x2)
    Tetromino.T: [[0, 0], [1, 0], [2, 0], [1, 1]], // T shape (3x2)
    Tetromino.Z: [[0, 0], [1, 0], [1, 1], [2, 1]], // Z shape (3x2)
  };
}

enum BlockShape {
  dot1x1,
  bar2x1,
  bar3x1,
  square2x2,
  Lshape3x2,
}

class BlockShapeValues {
  static const Map<BlockShape, Color> neonColors = {
    BlockShape.dot1x1: Color(0xFF00FFFF), // Cyan neon
    BlockShape.bar2x1: Color(0xFFFF00FF), // Magenta neon
    BlockShape.bar3x1: Color(0xFF00FF00), // Green neon
    BlockShape.square2x2: Color(0xFFFFFF00), // Yellow neon
    BlockShape.Lshape3x2: Color(0xFFFF4500), // Orange neon
  };

  static const Map<BlockShape, List<int>> coordinates = {
    BlockShape.dot1x1: [0, 0], // Single cell (1x1)
    BlockShape.bar2x1: [0, 0, 1, 0], // Horizontal 2-cell bar (2x1)
    BlockShape.bar3x1: [0, 0, 1, 0, 2, 0], // Horizontal 3-cell bar (3x1)
    BlockShape.square2x2: [0, 0, 1, 0, 0, 1, 1, 1], // 2x2 square
    BlockShape.Lshape3x2: [0, 0, 0, 1, 1, 1, 2, 1], // L shape (3x2)
  };
}