import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/game_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStats() {
    setState(() {
      _stats = ProfileService.instance.currentPlayerStats;
    });
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
            'STATISTICS',
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
            Tab(text: 'Overall'),
            Tab(text: 'vs AI'),
            Tab(text: '1v1'),
            Tab(text: '1v2'),
            Tab(text: '1v3'),
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
      body: _stats == null
          ? _buildNoStatsView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatsView(_stats!.totalStats, 'Overall'),
                _buildStatsView(_stats!.playerVsAi, 'Player vs AI'),
                _buildStatsView(_stats!.oneVsOne, '1 vs 1'),
                _buildStatsView(_stats!.oneVsTwo, '1 vs 2'),
                _buildStatsView(_stats!.oneVsThree, '1 vs 3'),
              ],
            ),
    );
  }

  Widget _buildNoStatsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF5A67D8).withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5A67D8).withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bar_chart,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Statistics Yet',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Play some games to see your statistics here!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView(GameModeStats stats, String title) {
    if (stats.matchesPlayed == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $title games played yet',
              style: const TextStyle(
                fontFamily: 'Futura',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start playing to see statistics',
              style: TextStyle(
                fontFamily: 'Futura',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overview Cards
          _buildOverviewCards(stats),
          const SizedBox(height: 24),

          // Performance Metrics
          _buildSectionTitle('Performance'),
          const SizedBox(height: 12),
          _buildPerformanceMetrics(stats),
          const SizedBox(height: 24),

          // Time Stats
          _buildSectionTitle('Time Statistics'),
          const SizedBox(height: 12),
          _buildTimeStats(stats),
          const SizedBox(height: 24),

          // Achievements
          _buildSectionTitle('Achievements'),
          const SizedBox(height: 12),
          _buildAchievements(stats),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildOverviewCards(GameModeStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Games Played',
            '${stats.matchesPlayed}',
            Icons.sports_esports,
            const Color(0xFF00D4FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Win Rate',
            '${stats.winRate.toStringAsFixed(1)}%',
            Icons.emoji_events,
            stats.winRate >= 50 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Futura',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(GameModeStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile('Wins', '${stats.wins}', Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile('Losses', '${stats.losses}', Colors.red),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile('Draws', '${stats.draws}', Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Blocks Won',
                '${stats.blocksDominated}',
                const Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                'Avg Blocks',
                stats.averageBlocksPerGame.toStringAsFixed(1),
                const Color(0xFF5A67D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Best Streak',
                '${stats.bestWinStreak}',
                Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                'Current Streak',
                '${stats.currentWinStreak}',
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeStats(GameModeStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Total Time',
                _formatDuration(stats.totalTimePlayedSeconds),
                const Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                'Avg Game',
                _formatDuration(stats.averageMatchDuration.round()),
                const Color(0xFF5A67D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Longest Game',
                _formatDuration(stats.longestMatchSeconds),
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                'Fastest Game',
                _formatDuration(stats.fastestMatchSeconds),
                Colors.green,
              ),
            ),
          ],
        ),
        if (stats.longestMoveTimeMs > 0 || stats.fastestMoveTimeMs > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Longest Move',
                  '${(stats.longestMoveTimeMs / 1000).toStringAsFixed(1)}s',
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Fastest Move',
                  '${(stats.fastestMoveTimeMs / 1000).toStringAsFixed(1)}s',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAchievements(GameModeStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Hat Tricks',
                '${stats.hatTricks}',
                Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                'Comeback Wins',
                '${stats.comebackWins}',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Domination Wins',
                '${stats.dominationWins}',
                const Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                'Quickest Win',
                stats.quickestWinTurns > 0 ? '${stats.quickestWinTurns} turns' : 'N/A',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Futura',
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}