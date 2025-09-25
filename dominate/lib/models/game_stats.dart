import '../game/dominate_game.dart';

/// Represents the result of a single match
enum MatchResult {
  win,
  loss,
  draw,
}

/// Statistics for a specific game mode
class GameModeStats {
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int blocksDominated;
  final int blocksLost;
  final int totalTimePlayedSeconds;
  final int longestMatchSeconds;
  final int fastestMatchSeconds;
  final int longestMoveTimeMs;
  final int fastestMoveTimeMs;
  final int currentWinStreak;
  final int bestWinStreak;
  final int hatTricks; // 3-win streaks achieved
  final int comebackWins; // Games won after being behind
  final int dominationWins; // Games won with >50% blocks
  final double totalBlocksPerGame;
  final int quickestWinTurns; // Fewest turns to win
  final int longestGame; // Most turns in a game
  final DateTime? lastWinTimestamp; // Timestamp of most recent win for ranking

  GameModeStats({
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.blocksDominated = 0,
    this.blocksLost = 0,
    this.totalTimePlayedSeconds = 0,
    this.longestMatchSeconds = 0,
    this.fastestMatchSeconds = 0,
    this.longestMoveTimeMs = 0,
    this.fastestMoveTimeMs = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    this.hatTricks = 0,
    this.comebackWins = 0,
    this.dominationWins = 0,
    this.totalBlocksPerGame = 0.0,
    this.quickestWinTurns = 0,
    this.longestGame = 0,
    this.lastWinTimestamp,
  });

  /// Calculate win rate percentage
  double get winRate {
    if (matchesPlayed == 0) return 0.0;
    return (wins / matchesPlayed) * 100;
  }

  /// Calculate average match duration in seconds
  double get averageMatchDuration {
    if (matchesPlayed == 0) return 0.0;
    return totalTimePlayedSeconds / matchesPlayed;
  }

  /// Calculate average blocks per game
  double get averageBlocksPerGame {
    if (matchesPlayed == 0) return 0.0;
    return blocksDominated / matchesPlayed;
  }

  /// Calculate average blocks lost per game
  double get averageBlocksLostPerGame {
    if (matchesPlayed == 0) return 0.0;
    return blocksLost / matchesPlayed;
  }

  /// Calculate domination rate (games with >50% blocks)
  double get dominationRate {
    if (matchesPlayed == 0) return 0.0;
    return (dominationWins / matchesPlayed) * 100;
  }

  /// Update stats with a new match result
  GameModeStats updateWithMatch({
    required MatchResult result,
    required int playerBlocks,
    required int opponentBlocks,
    required int matchDurationSeconds,
    required List<int> moveTimes,
    required int totalTurns,
    bool wasBehind = false,
  }) {
    final newMatchesPlayed = matchesPlayed + 1;
    final newWins = result == MatchResult.win ? wins + 1 : wins;
    final newLosses = result == MatchResult.loss ? losses + 1 : losses;
    final newDraws = result == MatchResult.draw ? draws + 1 : draws;

    final newBlocksDominated = blocksDominated + playerBlocks;
    final newBlocksLost = blocksLost + opponentBlocks;
    final newTotalTimePlayedSeconds = totalTimePlayedSeconds + matchDurationSeconds;

    final newLongestMatchSeconds = longestMatchSeconds == 0 || matchDurationSeconds > longestMatchSeconds
        ? matchDurationSeconds
        : longestMatchSeconds;
    final newFastestMatchSeconds = fastestMatchSeconds == 0 || matchDurationSeconds < fastestMatchSeconds
        ? matchDurationSeconds
        : fastestMatchSeconds;

    // Calculate move time stats
    final maxMoveTime = moveTimes.isNotEmpty ? moveTimes.reduce((a, b) => a > b ? a : b) : 0;
    final minMoveTime = moveTimes.isNotEmpty ? moveTimes.reduce((a, b) => a < b ? a : b) : 0;

    final newLongestMoveTimeMs = longestMoveTimeMs == 0 || maxMoveTime > longestMoveTimeMs
        ? maxMoveTime
        : longestMoveTimeMs;
    final newFastestMoveTimeMs = fastestMoveTimeMs == 0 || (minMoveTime > 0 && minMoveTime < fastestMoveTimeMs)
        ? minMoveTime
        : fastestMoveTimeMs;

    // Calculate streak
    final newCurrentWinStreak = result == MatchResult.win ? currentWinStreak + 1 : 0;
    final newBestWinStreak = newCurrentWinStreak > bestWinStreak ? newCurrentWinStreak : bestWinStreak;

    // Special achievements
    final isHatTrick = newCurrentWinStreak >= 3 && (currentWinStreak < 3);
    final newHatTricks = isHatTrick ? hatTricks + 1 : hatTricks;

    final isComebackWin = result == MatchResult.win && wasBehind;
    final newComebackWins = isComebackWin ? comebackWins + 1 : comebackWins;

    final isDominationWin = result == MatchResult.win && playerBlocks > 32;
    final newDominationWins = isDominationWin ? dominationWins + 1 : dominationWins;

    final newQuickestWinTurns = result == MatchResult.win && (quickestWinTurns == 0 || totalTurns < quickestWinTurns)
        ? totalTurns
        : quickestWinTurns;

    final newLongestGame = totalTurns > longestGame ? totalTurns : longestGame;

    // Update lastWinTimestamp if this is a win
    final newLastWinTimestamp = result == MatchResult.win ? DateTime.now() : lastWinTimestamp;

    return GameModeStats(
      matchesPlayed: newMatchesPlayed,
      wins: newWins,
      losses: newLosses,
      draws: newDraws,
      blocksDominated: newBlocksDominated,
      blocksLost: newBlocksLost,
      totalTimePlayedSeconds: newTotalTimePlayedSeconds,
      longestMatchSeconds: newLongestMatchSeconds,
      fastestMatchSeconds: newFastestMatchSeconds,
      longestMoveTimeMs: newLongestMoveTimeMs,
      fastestMoveTimeMs: newFastestMoveTimeMs,
      currentWinStreak: newCurrentWinStreak,
      bestWinStreak: newBestWinStreak,
      hatTricks: newHatTricks,
      comebackWins: newComebackWins,
      dominationWins: newDominationWins,
      totalBlocksPerGame: newBlocksDominated / newMatchesPlayed,
      quickestWinTurns: newQuickestWinTurns,
      longestGame: newLongestGame,
      lastWinTimestamp: newLastWinTimestamp,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'blocksDominated': blocksDominated,
      'blocksLost': blocksLost,
      'totalTimePlayedSeconds': totalTimePlayedSeconds,
      'longestMatchSeconds': longestMatchSeconds,
      'fastestMatchSeconds': fastestMatchSeconds,
      'longestMoveTimeMs': longestMoveTimeMs,
      'fastestMoveTimeMs': fastestMoveTimeMs,
      'currentWinStreak': currentWinStreak,
      'bestWinStreak': bestWinStreak,
      'hatTricks': hatTricks,
      'comebackWins': comebackWins,
      'dominationWins': dominationWins,
      'totalBlocksPerGame': totalBlocksPerGame,
      'quickestWinTurns': quickestWinTurns,
      'longestGame': longestGame,
      'lastWinTimestamp': lastWinTimestamp?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GameModeStats.fromJson(Map<String, dynamic> json) {
    return GameModeStats(
      matchesPlayed: json['matchesPlayed'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
      blocksDominated: json['blocksDominated'] ?? 0,
      blocksLost: json['blocksLost'] ?? 0,
      totalTimePlayedSeconds: json['totalTimePlayedSeconds'] ?? 0,
      longestMatchSeconds: json['longestMatchSeconds'] ?? 0,
      fastestMatchSeconds: json['fastestMatchSeconds'] ?? 0,
      longestMoveTimeMs: json['longestMoveTimeMs'] ?? 0,
      fastestMoveTimeMs: json['fastestMoveTimeMs'] ?? 0,
      currentWinStreak: json['currentWinStreak'] ?? 0,
      bestWinStreak: json['bestWinStreak'] ?? 0,
      hatTricks: json['hatTricks'] ?? 0,
      comebackWins: json['comebackWins'] ?? 0,
      dominationWins: json['dominationWins'] ?? 0,
      totalBlocksPerGame: json['totalBlocksPerGame'] ?? 0.0,
      quickestWinTurns: json['quickestWinTurns'] ?? 0,
      longestGame: json['longestGame'] ?? 0,
      lastWinTimestamp: json['lastWinTimestamp'] != null
          ? DateTime.parse(json['lastWinTimestamp'])
          : null,
    );
  }
}

/// Complete player statistics across all game modes
class PlayerStats {
  final GameModeStats playerVsAi;
  final GameModeStats oneVsOne;
  final GameModeStats oneVsTwo;
  final GameModeStats oneVsThree;
  final DateTime firstGameDate;
  final DateTime lastGameDate;

  PlayerStats({
    GameModeStats? playerVsAi,
    GameModeStats? oneVsOne,
    GameModeStats? oneVsTwo,
    GameModeStats? oneVsThree,
    DateTime? firstGameDate,
    DateTime? lastGameDate,
  }) :
    playerVsAi = playerVsAi ?? GameModeStats(),
    oneVsOne = oneVsOne ?? GameModeStats(),
    oneVsTwo = oneVsTwo ?? GameModeStats(),
    oneVsThree = oneVsThree ?? GameModeStats(),
    firstGameDate = firstGameDate ?? DateTime.now(),
    lastGameDate = lastGameDate ?? DateTime.now();

  /// Get stats for a specific game mode
  GameModeStats getStatsForMode(GameMode mode) {
    switch (mode) {
      case GameMode.playerVsAi:
        return playerVsAi;
      case GameMode.oneVsOne:
        return oneVsOne;
      case GameMode.oneVsTwo:
        return oneVsTwo;
      case GameMode.oneVsThree:
        return oneVsThree;
    }
  }

  /// Get total stats across all game modes
  GameModeStats get totalStats {
    return GameModeStats(
      matchesPlayed: playerVsAi.matchesPlayed + oneVsOne.matchesPlayed + oneVsTwo.matchesPlayed + oneVsThree.matchesPlayed,
      wins: playerVsAi.wins + oneVsOne.wins + oneVsTwo.wins + oneVsThree.wins,
      losses: playerVsAi.losses + oneVsOne.losses + oneVsTwo.losses + oneVsThree.losses,
      draws: playerVsAi.draws + oneVsOne.draws + oneVsTwo.draws + oneVsThree.draws,
      blocksDominated: playerVsAi.blocksDominated + oneVsOne.blocksDominated + oneVsTwo.blocksDominated + oneVsThree.blocksDominated,
      blocksLost: playerVsAi.blocksLost + oneVsOne.blocksLost + oneVsTwo.blocksLost + oneVsThree.blocksLost,
      totalTimePlayedSeconds: playerVsAi.totalTimePlayedSeconds + oneVsOne.totalTimePlayedSeconds + oneVsTwo.totalTimePlayedSeconds + oneVsThree.totalTimePlayedSeconds,
      longestMatchSeconds: [playerVsAi.longestMatchSeconds, oneVsOne.longestMatchSeconds, oneVsTwo.longestMatchSeconds, oneVsThree.longestMatchSeconds].reduce((a, b) => a > b ? a : b),
      fastestMatchSeconds: [playerVsAi.fastestMatchSeconds, oneVsOne.fastestMatchSeconds, oneVsTwo.fastestMatchSeconds, oneVsThree.fastestMatchSeconds].where((s) => s > 0).fold(0, (a, b) => a == 0 || b < a ? b : a),
      longestMoveTimeMs: [playerVsAi.longestMoveTimeMs, oneVsOne.longestMoveTimeMs, oneVsTwo.longestMoveTimeMs, oneVsThree.longestMoveTimeMs].reduce((a, b) => a > b ? a : b),
      fastestMoveTimeMs: [playerVsAi.fastestMoveTimeMs, oneVsOne.fastestMoveTimeMs, oneVsTwo.fastestMoveTimeMs, oneVsThree.fastestMoveTimeMs].where((s) => s > 0).fold(0, (a, b) => a == 0 || b < a ? b : a),
      bestWinStreak: [playerVsAi.bestWinStreak, oneVsOne.bestWinStreak, oneVsTwo.bestWinStreak, oneVsThree.bestWinStreak].reduce((a, b) => a > b ? a : b),
      hatTricks: playerVsAi.hatTricks + oneVsOne.hatTricks + oneVsTwo.hatTricks + oneVsThree.hatTricks,
      comebackWins: playerVsAi.comebackWins + oneVsOne.comebackWins + oneVsTwo.comebackWins + oneVsThree.comebackWins,
      dominationWins: playerVsAi.dominationWins + oneVsOne.dominationWins + oneVsTwo.dominationWins + oneVsThree.dominationWins,
      quickestWinTurns: [playerVsAi.quickestWinTurns, oneVsOne.quickestWinTurns, oneVsTwo.quickestWinTurns, oneVsThree.quickestWinTurns].where((s) => s > 0).fold(0, (a, b) => a == 0 || b < a ? b : a),
      longestGame: [playerVsAi.longestGame, oneVsOne.longestGame, oneVsTwo.longestGame, oneVsThree.longestGame].reduce((a, b) => a > b ? a : b),
    );
  }

  /// Update stats with a new match result
  PlayerStats updateWithMatch({
    required GameMode mode,
    required MatchResult result,
    required int playerBlocks,
    required int opponentBlocks,
    required int matchDurationSeconds,
    required List<int> moveTimes,
    required int totalTurns,
    bool wasBehind = false,
  }) {
    final now = DateTime.now();
    final newFirstGameDate = firstGameDate.isAfter(now) ? now : firstGameDate;

    switch (mode) {
      case GameMode.playerVsAi:
        return PlayerStats(
          playerVsAi: playerVsAi.updateWithMatch(
            result: result,
            playerBlocks: playerBlocks,
            opponentBlocks: opponentBlocks,
            matchDurationSeconds: matchDurationSeconds,
            moveTimes: moveTimes,
            totalTurns: totalTurns,
            wasBehind: wasBehind,
          ),
          oneVsOne: oneVsOne,
          oneVsTwo: oneVsTwo,
          oneVsThree: oneVsThree,
          firstGameDate: newFirstGameDate,
          lastGameDate: now,
        );
      case GameMode.oneVsOne:
        return PlayerStats(
          playerVsAi: playerVsAi,
          oneVsOne: oneVsOne.updateWithMatch(
            result: result,
            playerBlocks: playerBlocks,
            opponentBlocks: opponentBlocks,
            matchDurationSeconds: matchDurationSeconds,
            moveTimes: moveTimes,
            totalTurns: totalTurns,
            wasBehind: wasBehind,
          ),
          oneVsTwo: oneVsTwo,
          oneVsThree: oneVsThree,
          firstGameDate: newFirstGameDate,
          lastGameDate: now,
        );
      case GameMode.oneVsTwo:
        return PlayerStats(
          playerVsAi: playerVsAi,
          oneVsOne: oneVsOne,
          oneVsTwo: oneVsTwo.updateWithMatch(
            result: result,
            playerBlocks: playerBlocks,
            opponentBlocks: opponentBlocks,
            matchDurationSeconds: matchDurationSeconds,
            moveTimes: moveTimes,
            totalTurns: totalTurns,
            wasBehind: wasBehind,
          ),
          oneVsThree: oneVsThree,
          firstGameDate: newFirstGameDate,
          lastGameDate: now,
        );
      case GameMode.oneVsThree:
        return PlayerStats(
          playerVsAi: playerVsAi,
          oneVsOne: oneVsOne,
          oneVsTwo: oneVsTwo,
          oneVsThree: oneVsThree.updateWithMatch(
            result: result,
            playerBlocks: playerBlocks,
            opponentBlocks: opponentBlocks,
            matchDurationSeconds: matchDurationSeconds,
            moveTimes: moveTimes,
            totalTurns: totalTurns,
            wasBehind: wasBehind,
          ),
          firstGameDate: newFirstGameDate,
          lastGameDate: now,
        );
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'playerVsAi': playerVsAi.toJson(),
      'oneVsOne': oneVsOne.toJson(),
      'oneVsTwo': oneVsTwo.toJson(),
      'oneVsThree': oneVsThree.toJson(),
      'firstGameDate': firstGameDate.toIso8601String(),
      'lastGameDate': lastGameDate.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerVsAi: GameModeStats.fromJson(json['playerVsAi'] ?? {}),
      oneVsOne: GameModeStats.fromJson(json['oneVsOne'] ?? {}),
      oneVsTwo: GameModeStats.fromJson(json['oneVsTwo'] ?? {}),
      oneVsThree: GameModeStats.fromJson(json['oneVsThree'] ?? {}),
      firstGameDate: json['firstGameDate'] != null
          ? DateTime.parse(json['firstGameDate'])
          : DateTime.now(),
      lastGameDate: json['lastGameDate'] != null
          ? DateTime.parse(json['lastGameDate'])
          : DateTime.now(),
    );
  }
}

/// Helper extension for game mode display names
extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.playerVsAi:
        return 'Player vs AI';
      case GameMode.oneVsOne:
        return '1 vs 1';
      case GameMode.oneVsTwo:
        return '1 vs 2';
      case GameMode.oneVsThree:
        return '1 vs 3';
    }
  }

  String get shortName {
    switch (this) {
      case GameMode.playerVsAi:
        return 'vs AI';
      case GameMode.oneVsOne:
        return '1v1';
      case GameMode.oneVsTwo:
        return '1v2';
      case GameMode.oneVsThree:
        return '1v3';
    }
  }
}