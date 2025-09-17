import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/firebase_leaderboard_service.dart';
import '../models/player_profile.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _top10Players = [];
  PlayerPosition? _currentPlayerPosition;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🏆 Loading efficient leaderboard...');

      // Load top 10 players and current player position in parallel
      final futures = await Future.wait([ProfileService.instance.getTop10Leaderboard(), ProfileService.instance.getCurrentPlayerPosition()]);

      final top10 = futures[0] as List<LeaderboardEntry>;
      final playerPosition = futures[1] as PlayerPosition?;

      debugPrint('🏆 Leaderboard results: top10=${top10.length}, position=${playerPosition?.position}');

      setState(() {
        _top10Players = top10;
        _currentPlayerPosition = playerPosition;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🏆 Leaderboard error: $e');
      setState(() {
        _error = 'Failed to load leaderboard. Please ensure you have an internet connection and are signed in.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: Text('Leaderboard', style: TextStyle(fontFamily: 'Futura', fontWeight: FontWeight.bold)), elevation: 0, centerTitle: true, actions: [IconButton(onPressed: _loadLeaderboards, icon: Icon(Icons.refresh), tooltip: 'Refresh')]),
      body: Column(
        children: [
          // Player Position Display
          if (_currentPlayerPosition != null) _buildPlayerPositionHeader(),

          // Content
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingView()
                    : _error != null
                    ? _buildErrorView()
                    : _buildLeaderboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 3)), const SizedBox(height: 16), Text('Loading leaderboards...', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16))]));
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text('Leaderboard Empty', style: TextStyle(fontFamily: 'Futura', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_error ?? 'No players have competed yet. Be the first to start climbing the ranks!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _loadLeaderboards, icon: Icon(Icons.refresh), label: Text('Try Again'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D4FF), foregroundColor: Colors.black)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withValues(alpha: 0.3))),
              child: Column(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 24),
                  const SizedBox(height: 8),
                  Text('Create an Account', style: TextStyle(fontFamily: 'Futura', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Leaderboards require an internet connection and a registered account.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPositionHeader() {
    final position = _currentPlayerPosition!;
    final currentProfile = ProfileService.instance.currentProfile;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xFF00D4FF).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.6), width: 2), boxShadow: [BoxShadow(color: Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]),
      child: Row(
        children: [
          // Position
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: position.isInTop10 ? Colors.green : Color(0xFF00D4FF), borderRadius: BorderRadius.circular(30)),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('#${position.position}', style: TextStyle(fontFamily: 'Futura', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), if (!position.isInTop10) Text('YOUR', style: TextStyle(fontFamily: 'Futura', fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))])),
          ),
          const SizedBox(width: 16),

          // Player Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(currentProfile?.nickname ?? 'You', style: TextStyle(fontFamily: 'Futura', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), Text(position.isInTop10 ? 'In Top 10!' : 'Keep climbing!', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14))])),

          // Wins
          Column(children: [Text('${position.totalWins}', style: TextStyle(fontFamily: 'Futura', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), Text('VS AI Wins', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12))]),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_top10Players.isEmpty) {
      return _buildEmptyLeaderboard();
    }

    return Column(
      children: [
        // Top 10 Title
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(children: [Text('Top 10', style: TextStyle(fontFamily: 'Futura', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)), const SizedBox(height: 4), Text('VS AI Wins', style: TextStyle(fontFamily: 'Futura', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.0))]),
        ),

        // Top 10 List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _top10Players.length,
            itemBuilder: (context, index) {
              final entry = _top10Players[index];
              final rank = index + 1;
              return _buildLeaderboardItem(entry, rank);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.white.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            Text('No Rankings Yet', style: TextStyle(fontFamily: 'Futura', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Be the first to start climbing the ranks!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D4FF), foregroundColor: Colors.black), child: Text('Start Playing')),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank) {
    final isCurrentPlayer = ProfileService.instance.currentProfile?.id == entry.uid;

    // Medal colors for top 3
    Color? medalColor;
    IconData? medalIcon;
    if (rank == 1) {
      medalColor = Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      medalColor = Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      medalColor = Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? Color(0xFF00D4FF).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrentPlayer ? Color(0xFF00D4FF).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2), width: isCurrentPlayer ? 2 : 1),
        boxShadow: isCurrentPlayer ? [BoxShadow(color: Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank or Medal
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: medalColor?.withValues(alpha: 0.2) ?? Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: medalColor ?? Colors.white.withValues(alpha: 0.3))),
              child: Center(child: medalIcon != null ? Icon(medalIcon, color: medalColor, size: 20) : Text('#$rank', style: TextStyle(fontFamily: 'Futura', fontSize: 12, fontWeight: FontWeight.bold, color: medalColor ?? Colors.white))),
            ),
            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFF00D4FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  entry.avatarOption != null ? entry.avatarOption!.emoji : '👨‍🚀',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.nickname, style: TextStyle(fontFamily: 'Futura', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                      if (isCurrentPlayer) ...[
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Color(0xFF00D4FF).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.5))), child: Text('YOU', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildStatChip('${entry.totalWins} VS AI wins', Icons.emoji_events),
                ],
              ),
            ),

            // Wins (Large)
            Column(children: [Text('${entry.totalWins}', style: TextStyle(fontFamily: 'Futura', fontSize: 20, fontWeight: FontWeight.bold, color: _getWinsColor(entry.totalWins))), Text('VS AI', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12))]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)), const SizedBox(width: 4), Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11))]),
    );
  }

  Color _getWinsColor(int wins) {
    if (wins >= 50) return Colors.green;
    if (wins >= 20) return Color(0xFF00D4FF);
    if (wins >= 5) return Colors.orange;
    if (wins >= 1) return Colors.white;
    return Colors.grey;
  }
}
