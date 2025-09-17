import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/player_profile.dart';
import 'firebase_auth_service.dart';

/// Lightweight leaderboard entry for efficient Firebase storage and retrieval
class LeaderboardEntry {
  final String uid;
  final String nickname;
  final int totalWins;
  final AvatarOption? avatarOption;

  LeaderboardEntry({required this.uid, required this.nickname, required this.totalWins, this.avatarOption});

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'nickname': nickname,
      'totalWins': totalWins,
      'avatarOption': avatarOption?.name,
    };
  }

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      totalWins: data['totalWins'] ?? 0,
      avatarOption: data['avatarOption'] != null
          ? AvatarOption.values.firstWhere((e) => e.name == data['avatarOption'], orElse: () => AvatarOption.astronaut)
          : null,
    );
  }
}

/// Player's position info for showing their rank
class PlayerPosition {
  final int position;
  final int totalWins;
  final bool isInTop10;

  PlayerPosition({required this.position, required this.totalWins, required this.isInTop10});
}

class FirebaseLeaderboardService {
  static FirebaseLeaderboardService? _instance;
  static FirebaseLeaderboardService get instance => _instance ??= FirebaseLeaderboardService._();

  FirebaseLeaderboardService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  // Collection reference for efficient leaderboard queries
  CollectionReference get _leaderboardCollection => _firestore.collection('leaderboard');

  /// Update player's entry in the leaderboard
  Future<void> updatePlayerEntry({required String uid, required String nickname, required int totalWins, AvatarOption? avatarOption}) async {
    try {
      debugPrint('🏆 Updating leaderboard entry: $nickname ($totalWins wins)');

      final entry = LeaderboardEntry(
        uid: uid,
        nickname: nickname,
        totalWins: totalWins,
        avatarOption: avatarOption,
      );

      await _leaderboardCollection.doc(uid).set(entry.toFirestore());

      debugPrint('🏆 Leaderboard entry updated successfully');
    } catch (e) {
      debugPrint('🏆 Error updating leaderboard entry: $e');
      rethrow;
    }
  }

  /// Get top 10 players from leaderboard
  Future<List<LeaderboardEntry>> getTop10Players() async {
    try {
      debugPrint('🏆 Fetching top 10 players from leaderboard');

      final snapshot = await _leaderboardCollection.orderBy('totalWins', descending: true).limit(10).get();

      final top10 = snapshot.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList();

      debugPrint('🏆 Retrieved ${top10.length} top players');
      return top10;
    } catch (e) {
      debugPrint('🏆 Error fetching top 10 players: $e');
      return [];
    }
  }

  /// Get current player's position in the leaderboard
  Future<PlayerPosition?> getCurrentPlayerPosition() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('🏆 No authenticated user for position lookup');
        return null;
      }

      debugPrint('🏆 Looking up position for user: ${user.uid}');

      // Get current player's wins
      final playerDoc = await _leaderboardCollection.doc(user.uid).get();
      if (!playerDoc.exists) {
        debugPrint('🏆 Player not found in leaderboard');
        return null;
      }

      final playerData = playerDoc.data() as Map<String, dynamic>;
      final playerWins = playerData['totalWins'] ?? 0;

      // Count how many players have more wins (to determine position)
      final betterPlayersSnapshot = await _leaderboardCollection.where('totalWins', isGreaterThan: playerWins).get();

      final position = betterPlayersSnapshot.docs.length + 1;
      final isInTop10 = position <= 10;

      return PlayerPosition(position: position, totalWins: playerWins, isInTop10: isInTop10);
    } catch (e) {
      debugPrint('🏆 Error getting player position: $e');
      return null;
    }
  }

  /// Remove player from leaderboard (for cleanup)
  Future<void> removePlayerEntry(String uid) async {
    try {
      await _leaderboardCollection.doc(uid).delete();
      debugPrint('🏆 Removed player $uid from leaderboard');
    } catch (e) {
      debugPrint('🏆 Error removing player from leaderboard: $e');
    }
  }
}
