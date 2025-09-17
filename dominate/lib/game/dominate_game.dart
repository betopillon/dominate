import 'dart:async' as async;
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_board.dart';
import '../models/player.dart';
import '../models/game_stats.dart';
import '../services/profile_service.dart';

enum GameState { modeSelection, playing, gameOver, paused }

enum GameMode { playerVsAi, oneVsOne, oneVsTwo, oneVsThree }

class DominateGame extends FlameGame with HasCollisionDetection {
  late GameBoard gameBoard;
  late GamePlayers gamePlayers;
  GameState gameState = GameState.modeSelection;
  GameMode? currentGameMode;
  bool _isInitialized = false;
  VoidCallback? onGameOver;

  late double cellSize;
  late Vector2 boardPosition;
  late Vector2 boardSize;

  // Stats tracking
  DateTime? _gameStartTime;
  DateTime? _moveStartTime;
  final List<int> _moveTimes = [];
  int _totalTurns = 0;
  bool _wasPlayerBehind = false;

  // Consecutive moves tracking
  final Map<String, int> _blocksLostThisTurn = {};
  final Map<String, bool> _hasConsecutiveMove = {};
  String? _consecutiveMovePlayerId;

  // Move timer
  async.Timer? _moveTimer;
  async.Timer? _timerDisplayUpdateTimer;
  int _remainingTimeSeconds = 30;
  static const int moveTimeoutSeconds = 30;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize game components
    gameBoard = GameBoard();
    // Create initial dummy players (will be replaced when game starts)
    gamePlayers = GamePlayers(players: GamePlayers.createDefaultPlayers(2));

    // Calculate board layout
    _calculateBoardLayout();

    // Add game components
    await _initializeGameComponents();

    // Mark as initialized
    _isInitialized = true;
  }

  void _calculateBoardLayout() {
    // Calculate cell size based on screen size with padding
    final screenWidth = size.x;
    final screenHeight = size.y;
    final availableSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    final padding = availableSize * 0.01;
    final boardPixelSize = availableSize - (padding * 2);

    cellSize = boardPixelSize / GameBoard.boardSize;
    boardSize = Vector2.all(boardPixelSize);

    // Center the board on screen
    boardPosition = Vector2((screenWidth - boardPixelSize) / 2, (screenHeight - boardPixelSize) / 2);
  }

  Future<void> _initializeGameComponents() async {
    // Add space-themed board background with subtle glow
    final boardBackground = SpaceBoardBackground(size: boardSize, position: boardPosition);
    add(boardBackground);

    // Add grid lines and cells
    for (int row = 0; row < GameBoard.boardSize; row++) {
      for (int col = 0; col < GameBoard.boardSize; col++) {
        final cellPosition = Vector2(boardPosition.x + (col * cellSize), boardPosition.y + (row * cellSize));

        // Add cell background
        final cell = GameCell(position: cellPosition, size: Vector2.all(cellSize), row: row, col: col, game: this);
        add(cell);
      }
    }
  }

  void startGame(GameMode mode) {
    // Ensure the game is properly loaded before starting
    if (!_isInitialized) {
      // Schedule the start after the game has loaded
      Future.delayed(const Duration(milliseconds: 100), () => startGame(mode));
      return;
    }

    currentGameMode = mode;
    final playerCount = _getPlayerCountForMode(mode);

    gameBoard.reset();
    gameBoard.setStartingPositions(playerCount);
    final isAiMode = mode == GameMode.playerVsAi;

    // Get current player's nickname from profile service
    final currentProfile = ProfileService.instance.currentProfile;
    final humanPlayerName = currentProfile?.nickname;

    gamePlayers = GamePlayers(players: GamePlayers.createDefaultPlayers(playerCount, isAiMode: isAiMode, humanPlayerName: humanPlayerName));

    // Randomize starting player for fairer gameplay
    gamePlayers.randomizeStartingPlayer();

    gameState = GameState.playing;

    // Initialize stats tracking
    _gameStartTime = DateTime.now();
    _moveStartTime = DateTime.now();
    _moveTimes.clear();
    _totalTurns = 0;
    _wasPlayerBehind = false;

    // Update UI
    _updateGameDisplay();

    // Start move timer for the first player
    _startMoveTimer();

    // If AI mode and AI starts first, make AI move
    if (mode == GameMode.playerVsAi && gamePlayers.isCurrentPlayerAi) {
      _makeAiMove();
    }
  }

  int _getPlayerCountForMode(GameMode mode) {
    switch (mode) {
      case GameMode.playerVsAi:
      case GameMode.oneVsOne:
        return 2;
      case GameMode.oneVsTwo:
        return 3;
      case GameMode.oneVsThree:
        return 4;
    }
  }

  bool makeMove(int row, int col) {
    if (gameState != GameState.playing) return false;

    final currentPlayer = gamePlayers.currentPlayer;

    // First check if the move is valid
    if (!gameBoard.canPlaceBlock(row, col, currentPlayer.blockState)) {
      return false;
    }

    // Cancel the move timer since a move is being made
    _cancelMoveTimer();

    // Place the block and get steal information
    final stolenBlocks = gameBoard.placeBlockWithStealInfo(row, col, currentPlayer.blockState);

    // Track move time (only for human players)
    if (_moveStartTime != null && currentPlayer.id == 'player_1') {
      final moveTime = DateTime.now().difference(_moveStartTime!).inMilliseconds;
      _moveTimes.add(moveTime);
    }

    // Track stolen blocks for consecutive move calculation
    _updateStolenBlocksTracking(stolenBlocks);

    // Update scores
    final blockCounts = gameBoard.getBlockCounts();
    gamePlayers.updateAllScores(blockCounts);

    // Check if player was behind before this move
    if (currentPlayer.id == 'player_1') {
      final playerScore = currentPlayer.score;
      final maxOpponentScore = gamePlayers.players.where((p) => p.id != 'player_1').map((p) => p.score).fold(0, (max, score) => score > max ? score : max);

      if (playerScore < maxOpponentScore) {
        _wasPlayerBehind = true;
      }
    }

    _totalTurns++;

    // Check if game is over (board full OR no valid moves for any player)
    if (gameBoard.isBoardFull() || !_anyPlayerHasValidMoves()) {
      gameState = GameState.gameOver;
      _handleGameOver();
    } else {
      // Handle consecutive moves logic
      _handleTurnTransition();
    }

    _updateGameDisplay();
    return true;
  }

  void _updateStolenBlocksTracking(Map<BlockState, int> stolenBlocks) {
    // Reset tracking for all players at start of new round
    if (_consecutiveMovePlayerId == null) {
      _blocksLostThisTurn.clear();
      _hasConsecutiveMove.clear();
    }

    // Track blocks lost by each player
    for (final entry in stolenBlocks.entries) {
      final victimPlayer = gamePlayers.players.where((p) => p.blockState == entry.key).firstOrNull;

      if (victimPlayer != null) {
        _blocksLostThisTurn[victimPlayer.id] = (_blocksLostThisTurn[victimPlayer.id] ?? 0) + entry.value;
      }
    }
  }

  void _handleTurnTransition() {
    final currentPlayer = gamePlayers.currentPlayer;

    // Check if current player should get consecutive move
    if (_consecutiveMovePlayerId == currentPlayer.id) {
      // Player is using their consecutive move - clear it
      _consecutiveMovePlayerId = null;
    } else {
      // Normal turn transition
      _advanceToNextPlayerWithMoves();

      // Check if new current player qualifies for consecutive move
      final newCurrentPlayer = gamePlayers.currentPlayer;
      final blocksLost = _blocksLostThisTurn[newCurrentPlayer.id] ?? 0;

      if (blocksLost >= 3) {
        _consecutiveMovePlayerId = newCurrentPlayer.id;
        _hasConsecutiveMove[newCurrentPlayer.id] = true;
      }
    }

    // Start timing next move
    _moveStartTime = DateTime.now();

    // Start move timer for human players only
    _startMoveTimer();

    // If AI mode and now it's AI's turn, make AI move
    if (currentGameMode == GameMode.playerVsAi && gamePlayers.isCurrentPlayerAi) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeAiMove();
      });
    }
  }

  /// Check if current player has a consecutive move available
  bool get hasConsecutiveMove => _consecutiveMovePlayerId == gamePlayers.currentPlayer.id;

  /// Get remaining time for current move (for human players only)
  int get remainingMoveTime => _remainingTimeSeconds;

  bool _anyPlayerHasValidMoves() {
    final playerBlockStates = gamePlayers.players.map((p) => p.blockState).toList();
    return gameBoard.anyPlayerHasValidMoves(playerBlockStates);
  }

  void _advanceToNextPlayerWithMoves() {
    // Try up to the number of players to find someone who can move
    for (int i = 0; i < gamePlayers.playerCount; i++) {
      gamePlayers.nextTurn();
      final currentPlayer = gamePlayers.currentPlayer;

      // If current player has valid moves, stop here
      if (gameBoard.hasValidMoves(currentPlayer.blockState)) {
        return;
      }
    }

    // If we get here, no player has valid moves - game should end
    // This is handled in the main game loop check
  }

  void _handleGameOver() {
    // Save stats to profile
    _saveGameStats();
    // Notify UI that game is over
    onGameOver?.call();
  }

  Future<void> _saveGameStats() async {
    if (_gameStartTime == null || currentGameMode == null) return;

    try {
      final gameDuration = DateTime.now().difference(_gameStartTime!).inSeconds;
      final winners = gamePlayers.getWinners();
      final humanPlayer = gamePlayers.players.firstWhere((p) => p.id == 'player_1');

      // Determine match result for the human player
      MatchResult result;
      if (winners.contains(humanPlayer)) {
        result = MatchResult.win;
      } else if (winners.length > 1 && winners.any((w) => w.score == humanPlayer.score)) {
        result = MatchResult.draw;
      } else {
        result = MatchResult.loss;
      }

      // Calculate opponent blocks (sum of all non-human player blocks)
      final opponentBlocks = gamePlayers.players.where((p) => p.id != 'player_1').fold(0, (sum, player) => sum + player.score);

      // Update stats in profile service
      await ProfileService.instance.updateStats(gameMode: currentGameMode!, result: result, playerBlocks: humanPlayer.score, opponentBlocks: opponentBlocks, matchDurationSeconds: gameDuration, moveTimes: _moveTimes, totalTurns: _totalTurns, wasBehind: _wasPlayerBehind && result == MatchResult.win);
    } catch (e) {
      // If stats saving fails, don't crash the game
      debugPrint('Failed to save game stats: $e');
    }
  }

  void _updateGameDisplay() {
    // This will trigger UI updates in the components
    for (final component in children) {
      if (component is GameCell) {
        component.updateDisplay();
      }
    }
  }

  void resetGame() {
    _cancelMoveTimer(); // Cancel any active move timer
    if (_isInitialized) {
      gameBoard.reset();
      gamePlayers.reset();
    }
    gameState = GameState.modeSelection;
    currentGameMode = null;
    if (_isInitialized) {
      _updateGameDisplay();
    }
  }

  void _makeAiMove() {
    if (gameState != GameState.playing) return;

    final aiPlayer = gamePlayers.currentPlayer;
    if (aiPlayer.type != PlayerType.ai) return;

    final bestMove = _findBestAiMove(aiPlayer.blockState);
    if (bestMove != null) {
      makeMove(bestMove[0], bestMove[1]);
    }
  }

  List<int>? _findBestAiMove(BlockState aiPlayer) {
    // AI Strategy:
    // 1. Look for moves that steal opponent blocks (offensive)
    // 2. Look for moves that expand territory safely
    // 3. Block opponent expansion if possible (defensive)

    final validMoves = _getAllValidMoves(aiPlayer);
    if (validMoves.isEmpty) return null;

    // Score each move
    List<MapEntry<List<int>, int>> scoredMoves = [];

    for (final move in validMoves) {
      final score = _scoreAiMove(move[0], move[1], aiPlayer);
      scoredMoves.add(MapEntry(move, score));
    }

    // Sort by score (highest first)
    scoredMoves.sort((a, b) => b.value.compareTo(a.value));

    return scoredMoves.first.key;
  }

  List<List<int>> _getAllValidMoves(BlockState player) {
    final validMoves = <List<int>>[];

    for (int row = 0; row < GameBoard.boardSize; row++) {
      for (int col = 0; col < GameBoard.boardSize; col++) {
        if (gameBoard.canPlaceBlock(row, col, player)) {
          validMoves.add([row, col]);
        }
      }
    }

    return validMoves;
  }

  int _scoreAiMove(int row, int col, BlockState aiPlayer) {
    int score = 0;

    // Check all 8 directions (including diagonals) to see what we can steal
    final directions = [
      [-1, 0], // up
      [1, 0], // down
      [0, -1], // left
      [0, 1], // right
      [-1, -1], // up-left
      [-1, 1], // up-right
      [1, -1], // down-left
      [1, 1], // down-right
    ];

    int opponentBlocksNearby = 0;
    int aiBlocksNearby = 0;

    for (final direction in directions) {
      final newRow = row + direction[0];
      final newCol = col + direction[1];

      if (newRow >= 0 && newRow < GameBoard.boardSize && newCol >= 0 && newCol < GameBoard.boardSize) {
        final adjacentBlock = gameBoard.getBlock(newRow, newCol);

        if (adjacentBlock != BlockState.empty && adjacentBlock != aiPlayer) {
          // Can steal this opponent block
          score += 10;
          opponentBlocksNearby++;
        } else if (adjacentBlock == aiPlayer) {
          aiBlocksNearby++;
        }
      }
    }

    // Bonus for expanding connected territory
    score += aiBlocksNearby * 2;

    // Bonus for aggressive moves (stealing multiple blocks)
    if (opponentBlocksNearby > 1) {
      score += 5;
    }

    // Positional bonus - prefer center and corners
    final centerDistance = ((row - 3.5).abs() + (col - 3.5).abs());
    score += (7 - centerDistance).round();

    return score;
  }

  Vector2 getCellPosition(int row, int col) {
    return Vector2(boardPosition.x + (col * cellSize), boardPosition.y + (row * cellSize));
  }

  bool canPlaceAt(int row, int col) {
    if (!_isInitialized || gameState != GameState.playing) return false;
    if (!gameBoard.isPositionEmpty(row, col)) return false;

    final currentPlayer = gamePlayers.currentPlayer;
    return gameBoard.canPlaceBlock(row, col, currentPlayer.blockState);
  }

  void _startMoveTimer() {
    _cancelMoveTimer(); // Cancel any existing timer

    // Only start timer for human players
    if (gamePlayers.currentPlayer.type == PlayerType.human) {
      _remainingTimeSeconds = moveTimeoutSeconds;

      // Start the main timeout timer
      _moveTimer = async.Timer(Duration(seconds: moveTimeoutSeconds), () {
        _handleMoveTimeout();
      });

      // Start the display update timer (updates every second)
      _timerDisplayUpdateTimer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
        _remainingTimeSeconds--;
        if (_remainingTimeSeconds <= 0) {
          timer.cancel();
        }
      });
    }
  }

  void _cancelMoveTimer() {
    _moveTimer?.cancel();
    _moveTimer = null;
    _timerDisplayUpdateTimer?.cancel();
    _timerDisplayUpdateTimer = null;
  }

  void _handleMoveTimeout() {
    if (gameState != GameState.playing) return;

    // Make a random valid move for the current player
    final currentPlayer = gamePlayers.currentPlayer;
    final validMoves = _getAllValidMoves(currentPlayer.blockState);

    if (validMoves.isNotEmpty) {
      // Select a random move
      final randomIndex = DateTime.now().millisecondsSinceEpoch % validMoves.length;
      final move = validMoves[randomIndex];
      makeMove(move[0], move[1]);
    }
  }

  @override
  void onRemove() {
    _cancelMoveTimer();
    super.onRemove();
  }
}

class GameCell extends RectangleComponent with TapCallbacks {
  final int row;
  final int col;
  final DominateGame game;

  late SpaceBlockComponent blockComponent;
  late SpaceGridComponent borderComponent;

  GameCell({required Vector2 position, required Vector2 size, required this.row, required this.col, required this.game}) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add space-themed grid border
    borderComponent = SpaceGridComponent(size: size, cellSize: size.x);
    add(borderComponent);

    // Add space-themed block component (initially empty)
    blockComponent = SpaceBlockComponent(
      size: size * 0.85, // Slightly smaller than cell for glow effect
      position: size * 0.075, // Center it
    );
    add(blockComponent);

    updateDisplay();
  }

  void updateDisplay() {
    final blockState = game.gameBoard.getBlock(row, col);

    if (blockState == BlockState.empty) {
      // Check if this is a valid move location
      final canPlace = game.canPlaceAt(row, col);
      if (canPlace) {
        // Show light highlight for valid moves with subtle glow
        blockComponent.updateState(BlockState.empty, isValidMove: true);
      } else {
        blockComponent.updateState(BlockState.empty, isValidMove: false);
      }
    } else {
      // Block is occupied - trigger placement animation
      blockComponent.updateState(blockState, animate: true);
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (game.gameState == GameState.playing) {
      game.makeMove(row, col);
    }
    return true;
  }
}

// Dark gray board background
class SpaceBoardBackground extends RectangleComponent {
  SpaceBoardBackground({required Vector2 size, required Vector2 position}) : super(size: size, position: position);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Black board background
    final paint = Paint()..color = const Color(0xFF000000);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
  }
}

// Gray grid component for cell borders
class SpaceGridComponent extends RectangleComponent {
  final double cellSize;

  SpaceGridComponent({required Vector2 size, required this.cellSize}) : super(size: size);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // First draw black fill for the cell
    final fillPaint =
        Paint()
          ..color = const Color.fromARGB(255, 45, 45, 45)
          ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);

    // Then draw light gray border
    final borderPaint =
        Paint()
          ..color = const Color.fromARGB(255, 80, 80, 80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    canvas.drawRect(rect, borderPaint);
  }
}

// Enhanced space-themed block component with animations and glow effects
class SpaceBlockComponent extends RectangleComponent {
  static const double cornerRadius = 6.0;

  BlockState _currentState = BlockState.empty;
  bool _isValidMove = false;
  double _glowIntensity = 0.0;
  double _scaleAnimation = 1.0;
  DateTime? _lastStateChange;

  SpaceBlockComponent({required Vector2 size, required Vector2 position}) : super(size: size, position: position);

  void updateState(BlockState newState, {bool isValidMove = false, bool animate = false}) {
    final wasEmpty = _currentState == BlockState.empty;
    _currentState = newState;
    _isValidMove = isValidMove;

    if (animate && wasEmpty && newState != BlockState.empty) {
      // Trigger placement animation
      _lastStateChange = DateTime.now();
      _scaleAnimation = 0.5; // Start small
      _glowIntensity = 1.0; // Start with full glow
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle placement animation
    if (_lastStateChange != null) {
      final elapsed = DateTime.now().difference(_lastStateChange!).inMilliseconds;
      final progress = (elapsed / 300.0).clamp(0.0, 1.0); // 300ms animation

      if (progress < 1.0) {
        // Ease-out animation
        final eased = 1.0 - (1.0 - progress) * (1.0 - progress);
        _scaleAnimation = 0.5 + (0.5 * eased); // Scale from 0.5 to 1.0
        _glowIntensity = 1.0 - eased; // Glow fades out
      } else {
        _scaleAnimation = 1.0;
        _glowIntensity = 0.0;
        _lastStateChange = null;
      }
    }

    // Subtle breathing effect for valid moves
    if (_currentState == BlockState.empty && _isValidMove) {
      final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _glowIntensity = 0.2 + 0.1 * (0.5 + 0.5 * sin(time * 1.5));
    }
  }

  @override
  void render(Canvas canvas) {
    if (_currentState == BlockState.empty && !_isValidMove) return;

    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final animatedSize = size * _scaleAnimation;
    final animatedRect = Rect.fromLTWH(centerX - animatedSize.x / 2, centerY - animatedSize.y / 2, animatedSize.x, animatedSize.y);

    final rRect = RRect.fromRectAndRadius(animatedRect, const Radius.circular(cornerRadius));

    // Get color based on state
    Color blockColor;
    if (_currentState == BlockState.empty) {
      blockColor = const Color(0xFF808080).withValues(alpha: 0.4); // Valid move hint - light gray
    } else {
      blockColor = PlayerColors.getPlayerColor(_currentState);
    }

    // Draw glow effect if needed
    if (_glowIntensity > 0) {
      final glowPaint =
          Paint()
            ..color = blockColor.withValues(alpha: _glowIntensity * 0.6)
            ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8 * _glowIntensity);

      canvas.drawRRect(rRect, glowPaint);
    }

    // Draw main block with subtle inner glow
    final blockPaint = Paint()..color = blockColor;
    canvas.drawRRect(rRect, blockPaint);

    // Add inner highlight for 3D effect
    if (_currentState != BlockState.empty) {
      final highlightRect = Rect.fromLTWH(animatedRect.left + 2, animatedRect.top + 2, animatedRect.width - 4, animatedRect.height * 0.3);

      final highlightPaint =
          Paint()
            ..color = Colors.white.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawRRect(RRect.fromRectAndRadius(highlightRect, const Radius.circular(cornerRadius - 2)), highlightPaint);
    }
  }
}
