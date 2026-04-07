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

  static const Map<Tetromino, List<int>> initialCoordinates = {
    Tetromino.I: [4, 0, 5, 0, 6, 0, 7, 0], // Horizontal line
    Tetromino.J: [4, 0, 4, 1, 5, 1, 6, 1], // J shape
    Tetromino.L: [6, 0, 4, 1, 5, 1, 6, 1], // L shape
    Tetromino.O: [4, 0, 5, 0, 4, 1, 5, 1], // Square
    Tetromino.S: [5, 0, 6, 0, 4, 1, 5, 1], // S shape
    Tetromino.T: [4, 0, 5, 0, 6, 0, 5, 1], // T shape
    Tetromino.Z: [4, 0, 5, 0, 5, 1, 6, 1], // Z shape
  };
}