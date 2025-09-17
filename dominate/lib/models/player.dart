import 'dart:math';
import 'package:flutter/material.dart';
import 'game_board.dart';

enum PlayerType { human, ai }

class Player {
  final String id;
  final String name;
  final Color color;
  final BlockState blockState;
  final PlayerType type;
  int score;

  Player({
    required this.id,
    required this.name,
    required this.color,
    required this.blockState,
    required this.type,
    this.score = 0,
  });

  Player copyWith({
    String? id,
    String? name,
    Color? color,
    BlockState? blockState,
    PlayerType? type,
    int? score,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      blockState: blockState ?? this.blockState,
      type: type ?? this.type,
      score: score ?? this.score,
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PlayerColors {
  static const Color player1Color = Color(0xFF2196F3); // Blue
  static const Color player2Color = Color(0xFFF44336); // Red
  static const Color player3Color = Color(0xFF4CAF50); // Green
  static const Color player4Color = Color(0xFFFF9800); // Orange

  static Color getPlayerColor(BlockState blockState) {
    switch (blockState) {
      case BlockState.player1:
        return player1Color;
      case BlockState.player2:
        return player2Color;
      case BlockState.player3:
        return player3Color;
      case BlockState.player4:
        return player4Color;
      case BlockState.empty:
        return Colors.grey.shade300;
    }
  }

  static List<Color> getAvailableColors(int playerCount) {
    const colors = [player1Color, player2Color, player3Color, player4Color];
    return colors.take(playerCount).toList();
  }
}

class GamePlayers {
  final List<Player> _players;
  int _currentPlayerIndex;

  GamePlayers({required List<Player> players})
      : _players = List.from(players),
        _currentPlayerIndex = 0 {
    if (_players.isEmpty || _players.length > 4) {
      throw ArgumentError('Game must have 2-4 players');
    }
  }

  List<Player> get players => List.unmodifiable(_players);
  int get playerCount => _players.length;

  Player get currentPlayer => _players[_currentPlayerIndex];
  int get currentPlayerIndex => _currentPlayerIndex;

  void nextTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
  }

  void updatePlayerScore(String playerId, int newScore) {
    final playerIndex = _players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      _players[playerIndex] = _players[playerIndex].copyWith(score: newScore);
    }
  }

  void updateAllScores(Map<BlockState, int> blockCounts) {
    for (final player in _players) {
      final count = blockCounts[player.blockState] ?? 0;
      updatePlayerScore(player.id, count);
    }
  }

  List<Player> getWinners() {
    if (_players.isEmpty) return [];

    final maxScore = _players.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    return _players.where((p) => p.score == maxScore).toList();
  }

  Player? getPlayerByBlockState(BlockState blockState) {
    try {
      return _players.firstWhere((p) => p.blockState == blockState);
    } catch (e) {
      return null;
    }
  }

  void reset() {
    _currentPlayerIndex = 0;
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(score: 0);
    }
  }

  /// Randomly selects which player starts the game
  void randomizeStartingPlayer() {
    final random = Random();
    _currentPlayerIndex = random.nextInt(_players.length);
  }

  /// Get the first AI player, if any
  Player? get firstAiPlayer {
    try {
      return _players.firstWhere((player) => player.type == PlayerType.ai);
    } catch (e) {
      return null;
    }
  }

  /// Check if current player is AI
  bool get isCurrentPlayerAi => currentPlayer.type == PlayerType.ai;

  static List<Player> createDefaultPlayers(int playerCount, {bool isAiMode = false, String? humanPlayerName}) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError('Player count must be between 2 and 4');
    }

    final blockStates = [
      BlockState.player1,
      BlockState.player2,
      BlockState.player3,
      BlockState.player4,
    ];

    final colors = PlayerColors.getAvailableColors(playerCount);

    return List.generate(playerCount, (index) {
      // In AI mode, first player is human, rest are AI
      final isAi = isAiMode && index > 0;

      String playerName;
      if (isAi) {
        playerName = 'AI ${index + 1}';
      } else if (index == 0 && humanPlayerName != null && humanPlayerName.isNotEmpty) {
        // Use the actual player's nickname for the first human player
        playerName = humanPlayerName;
      } else {
        playerName = 'Player ${index + 1}';
      }

      return Player(
        id: 'player_${index + 1}',
        name: playerName,
        color: colors[index],
        blockState: blockStates[index],
        type: isAi ? PlayerType.ai : PlayerType.human,
        score: 0,
      );
    });
  }
}