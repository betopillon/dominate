import 'package:flutter/material.dart';
import '../models/game_board.dart';
import '../models/player.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF00D4FF), // Cyan
              Color(0xFF5A67D8), // Purple
            ],
          ).createShader(bounds),
          child: const Text(
            'HOW TO PLAY',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basics'),
            Tab(text: 'Movement'),
            Tab(text: 'Stealing'),
            Tab(text: 'Special'),
          ],
          labelStyle: const TextStyle(
            fontFamily: 'Futura',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Futura',
            fontSize: 12,
          ),
          indicatorColor: const Color(0xFF00D4FF),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicsTab(),
          _buildMovementTab(),
          _buildStealingTab(),
          _buildSpecialTab(),
        ],
      ),
    );
  }

  Widget _buildBasicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🎯 Game Objective'),
          _buildInfoCard(
            'Dominate the Board',
            'Occupy as many blocks as possible. The player with the most blocks when the game ends wins!',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🎮 Game Setup'),
          _buildInfoCard(
            'Board & Players',
            '• 8×8 grid with 64 total blocks\n'
            '• 2-4 players with unique colors\n'
            '• Players start in opposite corners\n'
            '• Turn-based gameplay',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🏆 Winning Conditions'),
          _buildInfoCard(
            'How to Win',
            '• Game ends when board is full OR no player can move\n'
            '• Player with most blocks wins\n'
            '• Ties are possible with equal block counts',
          ),
          const SizedBox(height: 16),

          // Starting positions visualization
          _buildSectionTitle('🎲 Starting Positions'),
          _buildStartingPositionsDemo(),
        ],
      ),
    );
  }

  Widget _buildMovementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📍 Placement Rules'),
          _buildInfoCard(
            'Adjacent Placement',
            'You can only place blocks adjacent (including diagonally) to your existing blocks.',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🔄 Movement Demo'),
          _buildMovementDemo(),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Valid Moves',
            '• Must place next to your own blocks\n'
            '• Can move in all 8 directions (horizontal, vertical, diagonal)\n'
            '• Cannot place on occupied spaces\n'
            '• Game shows valid moves with light highlights',
          ),
        ],
      ),
    );
  }

  Widget _buildStealingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('⚔️ Stealing Mechanism'),
          _buildInfoCard(
            'Capture Enemy Blocks',
            'When you place a block, you steal all enemy blocks directly adjacent to your new block!',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🎯 Stealing Demo'),
          _buildStealingDemo(),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Stealing Rules',
            '• Steal from all 8 adjacent directions\n'
            '• Only direct neighbors are stolen\n'
            '• Multiple players can be affected\n'
            '• Strategic positioning is key!',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('⚡ Consecutive Moves'),
          _buildInfoCard(
            'Comeback Mechanic',
            'If you lose 3+ blocks in one turn, you get a bonus consecutive move! Look for the lightning ⚡ icon.',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🎲 Random Start'),
          _buildInfoCard(
            'Fair Play',
            'Starting player is randomly selected each game for balanced gameplay.',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('⏰ Move Timer'),
          _buildInfoCard(
            'Keep It Moving',
            'You have 30 seconds to make each move. If time runs out, a random valid move will be made automatically.',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🤖 AI Strategy'),
          _buildInfoCard(
            'Smart Opponents',
            'AI players use advanced strategy:\n'
            '• Prioritize stealing opponent blocks\n'
            '• Expand connected territory\n'
            '• Consider positional advantages\n'
            '• Adapt to diagonal movements',
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('🏅 Tips for Success'),
          _buildInfoCard(
            'Pro Strategies',
            '• Control the center of the board\n'
            '• Set up chain reactions\n'
            '• Block opponent expansions\n'
            '• Use corners and edges strategically\n'
            '• Plan ahead for consecutive moves',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Futura',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00D4FF),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A67D8).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Futura',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Futura',
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartingPositionsDemo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Starting Positions',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildMiniBoard([
            [BlockState.player1, BlockState.empty, BlockState.empty, BlockState.player3],
            [BlockState.empty, BlockState.empty, BlockState.empty, BlockState.empty],
            [BlockState.empty, BlockState.empty, BlockState.empty, BlockState.empty],
            [BlockState.player4, BlockState.empty, BlockState.empty, BlockState.player2],
          ]),
          const SizedBox(height: 8),
          const Text(
            'Players start in corners',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementDemo() {
    return const AnimatedMovementDemo();
  }

  Widget _buildStealingDemo() {
    return const AnimatedStealingDemo();
  }

  Widget _buildMiniBoard(List<List<BlockState>> board) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: board.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) {
              return Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: PlayerColors.getPlayerColor(cell),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class AnimatedMovementDemo extends StatefulWidget {
  const AnimatedMovementDemo({super.key});

  @override
  State<AnimatedMovementDemo> createState() => _AnimatedMovementDemoState();
}

class _AnimatedMovementDemoState extends State<AnimatedMovementDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();

    _controller.addListener(() {
      if (_animation.value == 1.0) {
        setState(() {
          _step = (_step + 1) % 3;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<List<BlockState>> board = [
      [BlockState.empty, BlockState.empty, BlockState.empty, BlockState.empty],
      [BlockState.empty, BlockState.player1, BlockState.empty, BlockState.empty],
      [BlockState.empty, BlockState.empty, BlockState.empty, BlockState.empty],
      [BlockState.empty, BlockState.empty, BlockState.empty, BlockState.empty],
    ];

    if (_step >= 1) {
      board[1][2] = BlockState.player1; // Right of original
    }
    if (_step >= 2) {
      board[0][1] = BlockState.player1; // Up-left diagonal
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Valid Moves Animation',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildMiniBoard(board),
          const SizedBox(height: 8),
          Text(
            'Step ${_step + 1}: ${_getStepDescription(_step)}',
            style: const TextStyle(
              fontFamily: 'Futura',
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0: return 'Start with one block';
      case 1: return 'Place adjacent horizontally';
      case 2: return 'Place adjacent diagonally';
      default: return '';
    }
  }

  Widget _buildMiniBoard(List<List<BlockState>> board) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: board.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) {
              return Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: PlayerColors.getPlayerColor(cell),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class AnimatedStealingDemo extends StatefulWidget {
  const AnimatedStealingDemo({super.key});

  @override
  State<AnimatedStealingDemo> createState() => _AnimatedStealingDemoState();
}

class _AnimatedStealingDemoState extends State<AnimatedStealingDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _controller.repeat();

    _controller.addListener(() {
      setState(() {
        _step = (_controller.value * 3).floor();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<List<BlockState>> board = [
      [BlockState.empty, BlockState.player2, BlockState.empty],
      [BlockState.player2, BlockState.empty, BlockState.player2],
      [BlockState.empty, BlockState.player2, BlockState.empty],
    ];

    if (_step >= 1) {
      board[1][1] = BlockState.player1; // Blue places in center
    }
    if (_step >= 2) {
      // Steal all adjacent red blocks
      board[0][1] = BlockState.player1;
      board[1][0] = BlockState.player1;
      board[1][2] = BlockState.player1;
      board[2][1] = BlockState.player1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Stealing Animation',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildMiniBoard(board),
          const SizedBox(height: 8),
          Text(
            _getStealingStepDescription(_step),
            style: const TextStyle(
              fontFamily: 'Futura',
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStealingStepDescription(int step) {
    switch (step) {
      case 0: return 'Red blocks surround empty center';
      case 1: return 'Blue places block in center';
      case 2: return 'Blue steals all adjacent red blocks!';
      default: return '';
    }
  }

  Widget _buildMiniBoard(List<List<BlockState>> board) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: board.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) {
              return Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: PlayerColors.getPlayerColor(cell),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}