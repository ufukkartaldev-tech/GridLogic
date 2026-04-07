import 'constants.dart';

enum Tetromino {
  L,
  J,
  T,
  S,
  Z,
  I,
  O,
}

class Piece {
  Tetromino type;
  List<int> position;

  Piece({required this.type}) : position = [];

  void initializePiece() {
    // Start at top-center of the grid
    int startRow = 0;
    int startCol = (GameConstants.colLength ~/ 2) - 1;
    
    position = [startRow, startCol];
  }

  Color get color {
    switch (type) {
      case Tetromino.L:
        return Colors.orange;
      case Tetromino.J:
        return Colors.blue;
      case Tetromino.T:
        return Colors.purple;
      case Tetromino.S:
        return Colors.green;
      case Tetromino.Z:
        return Colors.red;
      case Tetromino.I:
        return Colors.cyan;
      case Tetromino.O:
        return Colors.yellow;
    }
  }
}