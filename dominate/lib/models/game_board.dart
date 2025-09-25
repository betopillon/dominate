
enum BlockState {
  empty,
  player1,
  player2,
  player3,
  player4,
}

class GameBoard {
  static const int boardSize = 8;
  static const int totalBlocks = boardSize * boardSize;

  late List<List<BlockState>> _grid;

  GameBoard() {
    _initializeBoard();
  }

  void _initializeBoard() {
    _grid = List.generate(
      boardSize,
      (i) => List.generate(boardSize, (j) => BlockState.empty),
    );
  }

  void setStartingPositions(int playerCount) {
    // Clear the board first
    _initializeBoard();

    // Set starting positions in opposite corners based on player count
    if (playerCount >= 2) {
      // Player 1: top-left corner
      _grid[0][0] = BlockState.player1;
      // Player 2: bottom-right corner
      _grid[boardSize - 1][boardSize - 1] = BlockState.player2;
    }

    if (playerCount >= 3) {
      // Player 3: top-right corner
      _grid[0][boardSize - 1] = BlockState.player3;
    }

    if (playerCount >= 4) {
      // Player 4: bottom-left corner
      _grid[boardSize - 1][0] = BlockState.player4;
    }
  }

  List<List<BlockState>> get grid => _grid;

  BlockState getBlock(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      throw ArgumentError('Position out of bounds: ($row, $col)');
    }
    return _grid[row][col];
  }

  bool placeBlock(int row, int col, BlockState player) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      return false;
    }

    if (_grid[row][col] != BlockState.empty) {
      return false;
    }

    // Check if player can place block here (must be adjacent to owned block)
    if (!_canPlaceBlock(row, col, player)) {
      return false;
    }

    _grid[row][col] = player;

    // Apply limited stealing rule: steal only first directly connected opponent blocks
    _stealAdjacentBlocks(row, col, player);

    return true;
  }

  /// Place block and return stolen blocks info for consecutive move tracking
  Map<BlockState, int> placeBlockWithStealInfo(int row, int col, BlockState player) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      return {};
    }

    if (_grid[row][col] != BlockState.empty) {
      return {};
    }

    // Check if player can place block here (must be adjacent to owned block)
    if (!_canPlaceBlock(row, col, player)) {
      return {};
    }

    _grid[row][col] = player;

    // Apply stealing and track what was stolen
    final stolenBlocks = _stealAdjacentBlocksWithTracking(row, col, player);

    return stolenBlocks;
  }

  bool _canPlaceBlock(int row, int col, BlockState player) {
    // Check all 8 directions (including diagonals) for an adjacent block owned by the same player
    final directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
      [-1, -1], // up-left
      [-1, 1],  // up-right
      [1, -1],  // down-left
      [1, 1],   // down-right
    ];

    for (final direction in directions) {
      final newRow = row + direction[0];
      final newCol = col + direction[1];

      // Check if position is valid and contains player's block
      if (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize) {
        if (_grid[newRow][newCol] == player) {
          return true;
        }
      }
    }

    return false;
  }

  void _stealAdjacentBlocks(int row, int col, BlockState player) {
    _stealAdjacentBlocksWithTracking(row, col, player);
  }

  Map<BlockState, int> _stealAdjacentBlocksWithTracking(int row, int col, BlockState player) {
    final stolenCount = <BlockState, int>{};

    // Check all 8 directions (including diagonals)
    final directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
      [-1, -1], // up-left
      [-1, 1],  // up-right
      [1, -1],  // down-left
      [1, 1],   // down-right
    ];

    for (final direction in directions) {
      final newRow = row + direction[0];
      final newCol = col + direction[1];

      // Check if position is valid
      if (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize) {
        final adjacentBlock = _grid[newRow][newCol];

        // If adjacent block belongs to another player, steal only that one block
        if (adjacentBlock != BlockState.empty && adjacentBlock != player) {
          _grid[newRow][newCol] = player;

          // Track stolen blocks
          stolenCount[adjacentBlock] = (stolenCount[adjacentBlock] ?? 0) + 1;
        }
      }
    }

    return stolenCount;
  }

  bool isPositionEmpty(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      return false;
    }
    return _grid[row][col] == BlockState.empty;
  }

  bool canPlaceBlock(int row, int col, BlockState player) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      return false;
    }

    if (_grid[row][col] != BlockState.empty) {
      return false;
    }

    return _canPlaceBlock(row, col, player);
  }

  bool isBoardFull() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_grid[i][j] == BlockState.empty) {
          return false;
        }
      }
    }
    return true;
  }

  bool hasValidMoves(BlockState player) {
    // Check if the player has any valid moves available
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_grid[i][j] == BlockState.empty && _canPlaceBlock(i, j, player)) {
          return true;
        }
      }
    }
    return false;
  }

  int getValidMoveCount(BlockState player) {
    // Count the number of valid moves available for the player
    int count = 0;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_grid[i][j] == BlockState.empty && _canPlaceBlock(i, j, player)) {
          count++;
        }
      }
    }
    return count;
  }

  bool canMoveStealBlocks(BlockState player) {
    // Check if ANY valid move can steal opponent blocks
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_grid[i][j] == BlockState.empty && _canPlaceBlock(i, j, player)) {
          // Check if this move would steal any blocks
          if (_wouldMoveStealBlocks(i, j, player)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _wouldMoveStealBlocks(int row, int col, BlockState player) {
    // Check if placing a block at this position would steal any opponent blocks
    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // cardinal directions
      [-1, -1], [-1, 1], [1, -1], [1, 1], // diagonals
    ];

    for (final direction in directions) {
      final newRow = row + direction[0];
      final newCol = col + direction[1];

      // Check if position is valid
      if (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize) {
        final adjacentBlock = _grid[newRow][newCol];

        // If adjacent block belongs to another player, this move would steal it
        if (adjacentBlock != BlockState.empty && adjacentBlock != player) {
          return true;
        }
      }
    }
    return false;
  }

  bool anyPlayerHasValidMoves(List<BlockState> players) {
    // Check if any player has valid moves
    for (final player in players) {
      if (hasValidMoves(player)) {
        return true;
      }
    }
    return false;
  }

  Map<BlockState, int> getBlockCounts() {
    Map<BlockState, int> counts = {
      BlockState.empty: 0,
      BlockState.player1: 0,
      BlockState.player2: 0,
      BlockState.player3: 0,
      BlockState.player4: 0,
    };

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        counts[_grid[i][j]] = counts[_grid[i][j]]! + 1;
      }
    }

    return counts;
  }

  List<BlockState> getWinners() {
    final counts = getBlockCounts();
    counts.remove(BlockState.empty);

    if (counts.isEmpty) return [];

    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    return counts.entries
        .where((entry) => entry.value == maxCount)
        .map((entry) => entry.key)
        .toList();
  }

  void reset() {
    _initializeBoard();
  }

  @override
  String toString() {
    String result = '';
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        switch (_grid[i][j]) {
          case BlockState.empty:
            result += '_ ';
            break;
          case BlockState.player1:
            result += '1 ';
            break;
          case BlockState.player2:
            result += '2 ';
            break;
          case BlockState.player3:
            result += '3 ';
            break;
          case BlockState.player4:
            result += '4 ';
            break;
        }
      }
      result += '\n';
    }
    return result;
  }
}