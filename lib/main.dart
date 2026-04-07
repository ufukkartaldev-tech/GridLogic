import 'package:flutter/material.dart';
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
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: GameBoard(),
              ),
            ),
            BlockPool(),
          ],
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
  late List<List<Color?>> gameGrid;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    gameGrid = List.generate(
      GameConstants.rowLength,
      (_) => List.generate(GameConstants.colLength, (_) => null),
    );
    createNewPiece();
  }

  void createNewPiece() {
    final tetrominoTypes = Tetromino.values;
    currentPiece = Piece(type: tetrominoTypes[random.nextInt(tetrominoTypes.length)]);
    currentPiece.initializePiece();
  }

  void placePiece() {
    if (currentPiece.position.length == 2) {
      int row = currentPiece.position[0];
      int col = currentPiece.position[1];
      if (row >= 0 && row < GameConstants.rowLength && col >= 0 && col < GameConstants.colLength) {
        gameGrid[row][col] = currentPiece.color;
        createNewPiece();
        setState(() {});
      }
    }
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
          
          return GestureDetector(
            onTap: () {
              if (isCurrentPiece) {
                placePiece();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isCurrentPiece ? currentPiece.color : (cellColor ?? Colors.transparent),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BlockPool extends StatefulWidget {
  const BlockPool({super.key});

  @override
  State<BlockPool> createState() => _BlockPoolState();
}

class _BlockPoolState extends State<BlockPool> {
  List<Piece> poolPieces = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    generatePoolPieces();
  }

  void generatePoolPieces() {
    poolPieces = List.generate(3, (_) {
      final tetrominoTypes = Tetromino.values;
      return Piece(type: tetrominoTypes[random.nextInt(tetrominoTypes.length)]);
    });
  }

  void refreshPool() {
    setState(() {
      generatePoolPieces();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...poolPieces.map((piece) => _buildBlockPreview(piece)),
          IconButton(
            onPressed: refreshPool,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Pool',
          ),
        ],
      ),
    );
  }

  Widget _buildBlockPreview(Piece piece) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: piece.color,
        border: Border.all(color: Colors.grey[600]!, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          piece.type.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
