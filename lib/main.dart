import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'constants.dart';
import 'piece.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grid Logic',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: GameBoard(),
        ),
      ),
    );
  }
}

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late Piece currentPiece;
  List<List<Color?>> gameGrid;
  Timer? gameTimer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    gameGrid = List.generate(
      GameConstants.rowLength,
      (_) => List.generate(GameConstants.colLength, (_) => null),
    );
    createNewPiece();
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void createNewPiece() {
    final tetrominoTypes = Tetromino.values;
    currentPiece = Piece(type: tetrominoTypes[random.nextInt(tetrominoTypes.length)]);
    currentPiece.initializePiece();
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      movePieceDown();
    });
  }

  void movePieceDown() {
    setState(() {
      int currentRow = currentPiece.position[0];
      int currentCol = currentPiece.position[1];
      int newRow = currentRow + 1;

      // Check if piece hits bottom or another landed block
      if (newRow >= GameConstants.rowLength || 
          (newRow < GameConstants.rowLength && gameGrid[newRow][currentCol] != null)) {
        // Fix piece to grid
        gameGrid[currentRow][currentCol] = currentPiece.color;
        // Create new piece
        createNewPiece();
      } else {
        // Move piece down
        currentPiece.position[0] = newRow;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: GameConstants.colLength * GameConstants.pixelSize,
      height: GameConstants.rowLength * GameConstants.pixelSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: GameConstants.colLength,
          childAspectRatio: 1.0,
        ),
        itemCount: GameConstants.rowLength * GameConstants.colLength,
        itemBuilder: (context, index) {
          int row = index ~/ GameConstants.colLength;
          int col = index % GameConstants.colLength;
          
          bool isCurrentPiece = currentPiece.position.length == 2 &&
              currentPiece.position[0] == row && 
              currentPiece.position[1] == col;
          
          Color? cellColor = gameGrid[row][col];
          
          return Container(
            decoration: BoxDecoration(
              color: isCurrentPiece ? currentPiece.color : (cellColor ?? Colors.transparent),
              border: Border.all(
                color: Colors.grey[700]!,
                width: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
