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

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late List<List<Color?>> gameGrid;
  late List<List<bool>> clearingCells;
  final Random random = Random();
  int score = 0;
  bool isGameOver = false;
  int comboCount = 0;
  int comboMultiplier = 1;
  late AnimationController _clearAnimationController;
  late AnimationController _comboAnimationController;
  late Animation<double> _clearAnimation;
  late Animation<double> _comboAnimation;

  @override
  void initState() {
    super.initState();
    gameGrid = List.generate(
      GameConstants.rowLength,
      (_) => List.generate(GameConstants.colLength, (_) => null),
    );
    clearingCells = List.generate(
      GameConstants.rowLength,
      (_) => List.generate(GameConstants.colLength, (_) => false),
    );
    
    _clearAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _clearAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _clearAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _comboAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _comboAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _comboAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    print('Game initialized with grid: ${GameConstants.rowLength}x${GameConstants.colLength}');
    print('Initial empty cells: ${GameConstants.rowLength * GameConstants.colLength}');
  }

  @override
  void dispose() {
    _clearAnimationController.dispose();
    _comboAnimationController.dispose();
    super.dispose();
  }

  bool isValidDrop(int row, int col) {
    return row >= 0 && 
           row < GameConstants.rowLength && 
           col >= 0 && 
           col < GameConstants.colLength && 
           gameGrid[row][col] == null;
  }

  void placePiece(int row, int col, Color color) {
    setState(() {
      gameGrid[row][col] = color;
      checkAndClearLines();
    });
    
    // Delay game over check to avoid immediate triggering
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        checkGameOver();
      }
    });
  }

  void checkAndClearLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];

    // Check for complete rows
    for (int row = 0; row < GameConstants.rowLength; row++) {
      bool isRowComplete = true;
      for (int col = 0; col < GameConstants.colLength; col++) {
        if (gameGrid[row][col] == null) {
          isRowComplete = false;
          break;
        }
      }
      if (isRowComplete) {
        rowsToClear.add(row);
      }
    }

    // Check for complete columns
    for (int col = 0; col < GameConstants.colLength; col++) {
      bool isColComplete = true;
      for (int row = 0; row < GameConstants.rowLength; row++) {
        if (gameGrid[row][col] == null) {
          isColComplete = false;
          break;
        }
      }
      if (isColComplete) {
        colsToClear.add(col);
      }
    }

    // Clear lines and calculate score
    if (rowsToClear.isNotEmpty || colsToClear.isNotEmpty) {
      int totalLines = rowsToClear.length + colsToClear.length;
      int basePoints = totalLines * 100;
      
      // Combo multiplier for multiple simultaneous clears
      int simultaneousMultiplier = totalLines > 1 ? totalLines : 1;
      
      // Calculate total points with multipliers
      int points = basePoints * simultaneousMultiplier * comboMultiplier;
      
      // Increment combo for consecutive clears
      comboCount++;
      if (comboCount > 1) {
        comboMultiplier = comboCount;
      } else {
        comboMultiplier = 1;
      }
      
      // Mark cells for clearing animation
      setState(() {
        for (int row in rowsToClear) {
          for (int col = 0; col < GameConstants.colLength; col++) {
            clearingCells[row][col] = true;
          }
        }
        
        for (int col in colsToClear) {
          for (int row = 0; row < GameConstants.rowLength; row++) {
            clearingCells[row][col] = true;
          }
        }
      });
      
      // Play combo animation if combo > 1
      if (comboCount > 1) {
        _comboAnimationController.forward().then((_) {
          _comboAnimationController.reset();
        });
      }
      
      // Play clear animation
      _clearAnimationController.forward().then((_) {
        setState(() {
          // Clear rows
          for (int row in rowsToClear) {
            for (int col = 0; col < GameConstants.colLength; col++) {
              gameGrid[row][col] = null;
              clearingCells[row][col] = false;
            }
          }
          
          // Clear columns
          for (int col in colsToClear) {
            for (int row = 0; row < GameConstants.rowLength; row++) {
              gameGrid[row][col] = null;
              clearingCells[row][col] = false;
            }
          }
          
          score += points;
        });
        _clearAnimationController.reset();
      });
    } else {
      // Reset combo if no lines cleared
      setState(() {
        comboCount = 0;
        comboMultiplier = 1;
      });
    }
  }

  bool canPlaceAnyBlock() {
    // Get the BlockPool state to access pool pieces
    final blockPoolState = context.findAncestorStateOfType<_BlockPoolState>();
    if (blockPoolState == null) {
      print('BlockPool state is null');
      return false;
    }

    // Count empty cells for debugging
    int emptyCells = 0;
    for (int row = 0; row < GameConstants.rowLength; row++) {
      for (int col = 0; col < GameConstants.colLength; col++) {
        if (gameGrid[row][col] == null) {
          emptyCells++;
        }
      }
    }
    print('Empty cells: $emptyCells, Pool pieces: ${blockPoolState.poolPieces.length}');

    // If no empty cells, game is definitely over
    if (emptyCells == 0) {
      return false;
    }

    // Check if at least one piece in the pool can be placed
    for (Piece piece in blockPoolState.poolPieces) {
      bool canPlaceThisPiece = false;
      // Check if this piece can be placed anywhere on the grid
      for (int row = 0; row < GameConstants.rowLength; row++) {
        for (int col = 0; col < GameConstants.colLength; col++) {
          if (gameGrid[row][col] == null) {
            // Found an empty spot for this piece
            canPlaceThisPiece = true;
            print('Found empty spot at ($row, $col) for piece ${piece.type.name}');
            break;
          }
        }
        if (canPlaceThisPiece) break;
      }
      if (canPlaceThisPiece) {
        print('At least one piece can be placed');
        return true; // At least one piece can be placed
      }
    }
    
    print('No valid placement found for any piece');
    // No valid placement found for any piece
    return false;
  }

  void checkGameOver() {
    if (!canPlaceAnyBlock()) {
      setState(() {
        isGameOver = true;
      });
    }
  }

  void restartGame() {
    setState(() {
      gameGrid = List.generate(
        GameConstants.rowLength,
        (_) => List.generate(GameConstants.colLength, (_) => null),
      );
      clearingCells = List.generate(
        GameConstants.rowLength,
        (_) => List.generate(GameConstants.colLength, (_) => false),
      );
      score = 0;
      isGameOver = false;
      comboCount = 0;
      comboMultiplier = 1;
    });
    
    // Refresh the block pool
    final blockPoolState = context.findAncestorStateOfType<_BlockPoolState>();
    blockPoolState?.refreshPool();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (comboCount > 1)
                    AnimatedBuilder(
                      animation: _comboAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_comboAnimation.value * 0.5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.8),
                                  blurRadius: 8.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            child: Text(
                              '${comboCount}x COMBO!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Container(
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
          
          Color? cellColor = gameGrid[row][col];
          
          return DragTarget<Color>(
            builder: (context, candidateData, rejectedData) {
              bool isHovering = candidateData.isNotEmpty;
              Color? ghostColor = isHovering ? candidateData.first : null;
              bool isClearing = clearingCells[row][col];
              
              return AnimatedBuilder(
                animation: _clearAnimation,
                builder: (context, child) {
                  Color cellColor = gameGrid[row][col];
                  Color displayColor;
                  
                  if (isClearing) {
                    // Flash animation for clearing cells
                    double opacity = 1.0 - _clearAnimation.value;
                    displayColor = (cellColor ?? Colors.white).withOpacity(opacity);
                  } else {
                    displayColor = cellColor ?? (ghostColor != null ? ghostColor.withOpacity(0.3) : Colors.transparent);
                  }
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: displayColor,
                      border: Border.all(
                        color: isHovering ? Colors.cyanAccent : Colors.grey[800]!.withOpacity(0.3),
                        width: isHovering ? 2.0 : 0.5,
                      ),
                      boxShadow: cellColor != null && !isClearing ? [
                        BoxShadow(
                          color: cellColor.withOpacity(0.8),
                          blurRadius: 8.0,
                          spreadRadius: 1.0,
                        ),
                        BoxShadow(
                          color: cellColor.withOpacity(0.6),
                          blurRadius: 4.0,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  );
                },
              );
            },
            onWillAccept: (color) {
              return isValidDrop(row, col);
            },
            onAccept: (color) {
              placePiece(row, col, color);
            },
          );
        },
      ),
        ),
          ],
        ),
        if (isGameOver)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Game Over!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Final Score: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Restart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    return Draggable<Color>(
      data: piece.color,
      feedback: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: piece.color,
          border: Border.all(color: Colors.cyanAccent, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: piece.color.withOpacity(0.8),
              blurRadius: 12.0,
              spreadRadius: 2.0,
            ),
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.6),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            piece.type.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(color: Colors.grey[600]!, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_upward,
            color: Colors.grey,
            size: 20,
          ),
        ),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: piece.color,
          border: Border.all(color: Colors.grey[700]!.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: piece.color.withOpacity(0.8),
              blurRadius: 10.0,
              spreadRadius: 1.5,
            ),
            BoxShadow(
              color: piece.color.withOpacity(0.6),
              blurRadius: 6.0,
              spreadRadius: 0.8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            piece.type.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
