import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'constants.dart';
import 'piece.dart';
import 'sound_manager.dart';
import 'high_score_manager.dart';
import 'commentary_manager.dart';
import 'particle_effect.dart';
import 'main_menu.dart';

void main() {
  runApp(MaterialApp(
    title: 'Grid Logic',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const MainMenu(),
    debugShowCheckedModeBanner: false,
  ));
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
  int highScore = 0;
  bool isGameOver = false;
  bool isPaused = false;
  int comboCount = 0;
  int comboMultiplier = 1;
  late AnimationController _clearAnimationController;
  late AnimationController _comboAnimationController;
  late AnimationController _commentaryAnimationController;
  late AnimationController _placementAnimationController;
  late Animation<double> _clearAnimation;
  late Animation<double> _comboAnimation;
  late Animation<double> _commentaryAnimation;
  late Animation<double> _placementAnimation;
  final SoundManager _soundManager = SoundManager();
  final HighScoreManager _highScoreManager = HighScoreManager();
  final CommentaryManager _commentaryManager = CommentaryManager();
  String? _currentCommentary;
  Timer? _commentaryTimer;
  Map<String, AnimationController> _cellAnimations = {};
  Map<String, ParticleEffect> _particleEffects = {};

  @override
  void initState() {
    super.initState();
    _soundManager.initialize();
    _loadHighScore();
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
    
    _commentaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _commentaryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _commentaryAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _placementAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _placementAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _placementAnimationController,
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
    _commentaryAnimationController.dispose();
    _placementAnimationController.dispose();
    _commentaryTimer?.cancel();
    _soundManager.dispose();
    
    // Dispose cell animations and particle effects
    for (var controller in _cellAnimations.values) {
      controller.dispose();
    }
    // Dispose particle effects
    _particleEffects.clear();
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
    _soundManager.playDrop();
    HapticFeedback.lightImpact(); // Light impact for block placement
    
    // Create unique key for this cell
    String cellKey = '${row}_$col';
    
    // Dispose existing animation for this cell
    _cellAnimations[cellKey]?.dispose();
    
    // Create new animation controller for this cell
    _cellAnimations[cellKey] = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    setState(() {
      gameGrid[row][col] = color;
      checkAndClearLines();
    });
    
    // Play placement animation
    _cellAnimations[cellKey]!.forward().then((_) {
      _cellAnimations[cellKey]!.reverse().then((_) {
        _cellAnimations[cellKey]!.dispose();
        _cellAnimations.remove(cellKey);
      });
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
      // Play explosion sound synced with animation
      Future.delayed(const Duration(milliseconds: 200), () {
        _soundManager.playExplosion();
      });
      HapticFeedback.heavyImpact(); // Heavy impact for line clear
      
      int totalLines = rowsToClear.length + colsToClear.length;
      int basePoints = totalLines * 100;
      
      // Combo multiplier for multiple simultaneous clears
      int simultaneousMultiplier = totalLines > 1 ? totalLines : 1;
      
      // Calculate total points with multipliers
      int points = basePoints * simultaneousMultiplier * comboMultiplier;
      
      // Create particle effects for cleared lines
      _createClearParticles(rowsToClear, colsToClear);
      
      // Increment combo for consecutive clears
      comboCount++;
      if (comboCount > 1) {
        comboMultiplier = comboCount;
        _showCommentary(_commentaryManager.getComboCommentary());
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
          
          // Update high score if current score exceeds it
          if (score > highScore) {
            highScore = score;
            _highScoreManager.saveHighScore(score);
            _showCommentary(_commentaryManager.getHighScoreCommentary());
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

  void _showCommentary(String commentary) {
    _commentaryTimer?.cancel();
    setState(() {
      _currentCommentary = commentary;
    });
    _commentaryAnimationController.forward().then((_) {
      _commentaryAnimationController.reset();
    });
    
    // Hide commentary after 3 seconds
    _commentaryTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentCommentary = null;
        });
      }
    });
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
      _showCommentary(_commentaryManager.getGameOverCommentary());
    }
  }

  Future<void> _loadHighScore() async {
    highScore = await _highScoreManager.getHighScore();
    setState(() {});
  }

  void _updateScore(int points) {
    setState(() {
      score += points;
      
      // Update high score if current score exceeds it
      if (score > highScore) {
        highScore = score;
        _highScoreManager.saveHighScore(score);
      }
    });
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

  void _createClearParticles(List<int> rowsToClear, List<int> colsToClear) {
    for (int row in rowsToClear) {
      _createRowParticles(row);
    }
    for (int col in colsToClear) {
      _createColumnParticles(col);
    }
  }

  void _createRowParticles(int row) {
    List<Particle> particles = [];
    for (int col = 0; col < GameConstants.colLength; col++) {
      particles.add(Particle(
        x: col * GameConstants.pixelSize + GameConstants.pixelSize / 2,
        y: row * GameConstants.pixelSize + GameConstants.pixelSize / 2,
        size: 4.0,
        color: Colors.cyanAccent,
      ));
    }
    String key = 'row_$row';
    _showParticleEffect(key, particles);
  }

  void _createColumnParticles(int col) {
    List<Particle> particles = [];
    for (int row = 0; row < GameConstants.rowLength; row++) {
      particles.add(Particle(
        x: col * GameConstants.pixelSize + GameConstants.pixelSize / 2,
        y: row * GameConstants.pixelSize + GameConstants.pixelSize / 2,
        size: 4.0,
        color: Colors.purple,
      ));
    }
    String key = 'col_$col';
    _showParticleEffect(key, particles);
  }

  void _restartGame() {
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

  void _showParticleEffect(String key, List<Particle> particles) {
    // Remove existing effect if it exists
    _particleEffects.remove(key);
    
    // Create new particle effect
    setState(() {
      _particleEffects[key] = ParticleEffect(
        particles: particles,
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Score and Controls
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCORE: $score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'HIGH: $highScore',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => isPaused = !isPaused),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPaused ? Icons.play_arrow : Icons.pause,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPaused ? 'RESUME' : 'PAUSE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
              if (!isPaused)
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
                          String cellKey = '${row}_$col';
                          bool isPlacing = _cellAnimations.containsKey(cellKey);
                          
                          return AnimatedBuilder(
                            animation: Listenable.merge([_clearAnimation, _cellAnimations[cellKey] ?? const AlwaysStoppedAnimation(0.0)]),
                            builder: (context, child) {
                              Color? cellColor = gameGrid[row][col];
                              Color displayColor;
                              double scale = 1.0;
                              
                              if (isClearing) {
                                // Flash animation for clearing cells
                                double opacity = 1.0 - _clearAnimation.value;
                                displayColor = (cellColor ?? Colors.white).withOpacity(opacity);
                              } else {
                                displayColor = cellColor ?? (ghostColor != null ? ghostColor.withOpacity(0.3) : Colors.transparent);
                                
                                // Add placement animation
                                if (isPlacing && _cellAnimations[cellKey] != null) {
                                  scale = 1.0 + (_placementAnimation.value * 0.3);
                                }
                              }
                              
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: displayColor,
                                    border: Border.all(
                                      color: isHovering ? Colors.cyanAccent : Colors.grey[800]!.withOpacity(0.3),
                                      width: isHovering ? 2.0 : 0.5,
                                    ),
                                    boxShadow: cellColor != null && !isClearing ? [
                                      BoxShadow(
                                        color: cellColor.withOpacity(0.9),
                                        blurRadius: 12.0,
                                        spreadRadius: 2.0,
                                      ),
                                      BoxShadow(
                                        color: cellColor.withOpacity(0.7),
                                        blurRadius: 6.0,
                                        spreadRadius: 1.0,
                                      ),
                                      BoxShadow(
                                        color: cellColor.withOpacity(0.5),
                                        blurRadius: 3.0,
                                        spreadRadius: 0.5,
                                      ),
                                    ] : null,
                                  ),
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
              if (!isPaused)
                const BlockPool(),
              if (isPaused)
                _buildPauseMenu(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseMenu() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.cyanAccent, width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.8),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildMenuButton('RESUME', Colors.green, () => setState(() => isPaused = false)),
              const SizedBox(height: 20),
              _buildMenuButton('RESTART', Colors.orange, _restartGame),
              const SizedBox(height: 20),
              _buildMenuButton('QUIT', Colors.red, () => Navigator.popUntil(context, (route) => route.isFirst)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
  }
}

class BlockPool extends StatefulWidget {
  const BlockPool({super.key});

  @override
  State<BlockPool> createState() => _BlockPoolState();
}

class _BlockPoolState extends State<BlockPool> with TickerProviderStateMixin {
  List<Piece> poolPieces = [];
  final Random random = Random();
  final SoundManager _soundManager = SoundManager();
  String? _currentCommentary;
  late AnimationController _commentaryAnimationController;
  late Animation<double> _commentaryAnimation;
  Map<String, ParticleEffect> _particleEffects = {};

  @override
  void initState() {
    super.initState();
    _soundManager.initialize();
    
    _commentaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _commentaryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _commentaryAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    generatePoolPieces();
  }

  @override
  void dispose() {
    _commentaryAnimationController.dispose();
    _soundManager.dispose();
    _particleEffects.clear();
    super.dispose();
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...poolPieces.map((piece) => _buildBlockPreview(piece)),
        IconButton(
          onPressed: refreshPool,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Pool',
        ),
      ],
    );
  }

  Widget _buildBlockPreview(Piece piece) {
    return Draggable<Color>(
      data: piece.color,
      onDragStarted: () {
        _soundManager.playClick();
        HapticFeedback.selectionClick(); // Selection click for block pickup
      },
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
