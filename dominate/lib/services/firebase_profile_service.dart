import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/player_profile.dart';
import '../models/game_stats.dart';
import '../game/dominate_game.dart';
import 'firebase_auth_service.dart';

class FirebaseProfileService {
  static FirebaseProfileService? _instance;
  static FirebaseProfileService get instance => _instance ??= FirebaseProfileService._();

  FirebaseProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  // Collection references
  CollectionReference get _profilesCollection => _firestore.collection('profiles');

  // Create or update profile in Firestore
  Future<void> saveProfile(PlayerProfile profile) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user for profile saving');
        return;
      }

      // Convert profile to Firestore document
      final profileData = _profileToFirestoreData(profile, user.uid);

      await _profilesCollection.doc(user.uid).set(profileData, SetOptions(merge: true));
      debugPrint('Profile saved successfully for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error saving profile: $e');
      // Check if it's a permission error
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('Permission denied when saving profile - check Firebase rules and authentication');
      }
      // Don't rethrow - let the app continue gracefully
    }
  }

  // Load profile from Firestore
  Future<PlayerProfile?> loadProfile() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user for profile loading');
        return null;
      }

      final doc = await _profilesCollection.doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _firestoreDataToProfile(data, user.uid);
      }

      return null;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      // Check if it's a permission error
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('Permission denied when loading profile - user may need authentication');
      }
      return null;
    }
  }

  // Create profile for new Firebase user
  Future<PlayerProfile> createProfileForUser({required String email, required String nickname, required AvatarType avatarType, String? imagePath, AvatarOption? avatarOption}) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final now = DateTime.now();
    final profile = PlayerProfile(id: user.uid, email: email, nickname: nickname, avatarType: avatarType, imagePath: imagePath, avatarOption: avatarOption, createdAt: now, updatedAt: now, isEmailVerified: user.emailVerified, stats: PlayerStats());

    await saveProfile(profile);
    return profile;
  }

  // Update profile
  Future<PlayerProfile?> updateProfile({PlayerProfile? currentProfile, String? email, String? nickname, AvatarType? avatarType, String? imagePath, AvatarOption? avatarOption, bool? isEmailVerified, PlayerStats? stats}) async {
    try {
      // Use provided current profile or load from Firebase if not provided
      final baseProfile = currentProfile ?? await loadProfile();
      if (baseProfile == null) return null;

      final updatedProfile = baseProfile.copyWith(email: email, nickname: nickname, avatarType: avatarType, imagePath: imagePath, avatarOption: avatarOption, isEmailVerified: isEmailVerified, stats: stats);

      await saveProfile(updatedProfile);
      return updatedProfile;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return null;
    }
  }

  // Update player stats
  Future<PlayerProfile?> updateStats({PlayerProfile? currentProfile, required GameMode gameMode, required MatchResult result, required int playerBlocks, required int opponentBlocks, required int matchDurationSeconds, required List<int> moveTimes, required int totalTurns, bool wasBehind = false}) async {
    try {
      final baseProfile = currentProfile ?? await loadProfile();
      if (baseProfile == null) return null;

      final updatedStats = baseProfile.stats.updateWithMatch(mode: gameMode, result: result, playerBlocks: playerBlocks, opponentBlocks: opponentBlocks, matchDurationSeconds: matchDurationSeconds, moveTimes: moveTimes, totalTurns: totalTurns, wasBehind: wasBehind);

      return await updateProfile(currentProfile: baseProfile, stats: updatedStats);
    } catch (e) {
      debugPrint('Error updating stats: $e');
      return null;
    }
  }

  // Delete profile
  Future<bool> deleteProfile() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      await _profilesCollection.doc(user.uid).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      return false;
    }
  }

  // Get top players for leaderboard
  Future<List<PlayerProfile>> getTopPlayers({GameMode? gameMode, int limit = 100}) async {
    try {
      debugPrint('🏆 Firebase getTopPlayers: gameMode=$gameMode, limit=$limit');

      // Get all players without complex ordering to avoid index requirements
      QuerySnapshot snapshot;

      try {
        // First try registered players only
        snapshot = await _profilesCollection.where('isRegistered', isEqualTo: true).get();
        debugPrint('🏆 Firebase registered players found: ${snapshot.docs.length}');
      } catch (e) {
        debugPrint('🏆 Error with isRegistered filter: $e, trying all players');
        // Fallback to all players
        snapshot = await _profilesCollection.get();
        debugPrint('🏆 Firebase all players found: ${snapshot.docs.length}');
      }

      // Convert docs to PlayerProfile objects
      final allPlayers =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _firestoreDataToProfile(data, doc.id);
          }).toList();

      debugPrint('🏆 Firebase converted ${allPlayers.length} players');

      // Sort client-side based on game mode (by wins, then win rate)
      allPlayers.sort((a, b) {
        int aWins, bWins;
        double aWinRate, bWinRate;

        if (gameMode != null) {
          // Get stats for specific game mode
          final aStats = a.stats.getStatsForMode(gameMode);
          final bStats = b.stats.getStatsForMode(gameMode);
          aWins = aStats.wins;
          bWins = bStats.wins;
          aWinRate = aStats.winRate;
          bWinRate = bStats.winRate;
        } else {
          // Use total stats
          aWins = a.stats.totalStats.wins;
          bWins = b.stats.totalStats.wins;
          aWinRate = a.stats.totalStats.winRate;
          bWinRate = b.stats.totalStats.winRate;
        }

        // Primary sort by number of wins
        if (bWins != aWins) {
          return bWins.compareTo(aWins);
        }

        // Secondary sort by win rate for same number of wins
        if ((bWinRate - aWinRate).abs() < 0.01) {
          final aMatches = gameMode != null ? a.stats.getStatsForMode(gameMode).matchesPlayed : a.stats.totalStats.matchesPlayed;
          final bMatches = gameMode != null ? b.stats.getStatsForMode(gameMode).matchesPlayed : b.stats.totalStats.matchesPlayed;
          return bMatches.compareTo(aMatches);
        }

        return bWinRate.compareTo(aWinRate);
      });

      // Filter out players with no games if we have enough players
      final playersWithGames =
          allPlayers.where((p) {
            final stats = gameMode != null ? p.stats.getStatsForMode(gameMode) : p.stats.totalStats;
            return stats.matchesPlayed > 0;
          }).toList();

      final resultPlayers = playersWithGames.isNotEmpty ? playersWithGames : allPlayers;

      final limitedPlayers = resultPlayers.take(limit).toList();
      debugPrint('🏆 Firebase returning ${limitedPlayers.length} sorted players');

      return limitedPlayers;
    } catch (e) {
      debugPrint('🏆 Error getting top players: $e');
      return [];
    }
  }

  // Search profiles by nickname
  Future<List<PlayerProfile>> searchProfilesByNickname(String nickname) async {
    try {
      final snapshot = await _profilesCollection.where('nickname', isGreaterThanOrEqualTo: nickname).where('nickname', isLessThan: '$nickname\uf8ff').where('isRegistered', isEqualTo: true).limit(50).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _firestoreDataToProfile(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error searching profiles: $e');
      return [];
    }
  }

  // Check if nickname is available
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final snapshot = await _profilesCollection.where('nickname', isEqualTo: nickname).where('isRegistered', isEqualTo: true).limit(1).get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking nickname availability: $e');
      return false;
    }
  }

  // Convert PlayerProfile to Firestore data
  Map<String, dynamic> _profileToFirestoreData(PlayerProfile profile, String userId) {
    return {
      'id': userId,
      'email': profile.email,
      'nickname': profile.nickname,
      'avatarType': profile.avatarType.name,
      'imagePath': profile.imagePath,
      'avatarOption': profile.avatarOption?.name,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
      'isEmailVerified': profile.isEmailVerified,
      'isRegistered': profile.isRegistered,
      'stats': _statsToFirestoreData(profile.stats),
    };
  }

  // Convert Firestore data to PlayerProfile
  PlayerProfile _firestoreDataToProfile(Map<String, dynamic> data, String userId) {
    return PlayerProfile(
      id: userId,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      avatarType: AvatarType.values.firstWhere((e) => e.name == data['avatarType'], orElse: () => AvatarType.avatar),
      imagePath: data['imagePath'],
      avatarOption: data['avatarOption'] != null ? AvatarOption.values.firstWhere((e) => e.name == data['avatarOption'], orElse: () => AvatarOption.astronaut) : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      stats: data['stats'] != null ? _firestoreDataToStats(data['stats']) : PlayerStats(),
    );
  }

  // Convert PlayerStats to Firestore data
  Map<String, dynamic> _statsToFirestoreData(PlayerStats stats) {
    return {
      'playerVsAi': _gameModeStatsToFirestore(stats.playerVsAi),
      'oneVsOne': _gameModeStatsToFirestore(stats.oneVsOne),
      'oneVsTwo': _gameModeStatsToFirestore(stats.oneVsTwo),
      'oneVsThree': _gameModeStatsToFirestore(stats.oneVsThree),
      'totalStats': _gameModeStatsToFirestore(stats.totalStats),
      'firstGameDate': Timestamp.fromDate(stats.firstGameDate),
      'lastGameDate': Timestamp.fromDate(stats.lastGameDate),
    };
  }

  // Convert Firestore data to PlayerStats
  PlayerStats _firestoreDataToStats(Map<String, dynamic> data) {
    return PlayerStats(
      playerVsAi: _firestoreToGameModeStats(data['playerVsAi']),
      oneVsOne: _firestoreToGameModeStats(data['oneVsOne']),
      oneVsTwo: _firestoreToGameModeStats(data['oneVsTwo']),
      oneVsThree: _firestoreToGameModeStats(data['oneVsThree']),
      firstGameDate: (data['firstGameDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastGameDate: (data['lastGameDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert GameModeStats to Firestore
  Map<String, dynamic> _gameModeStatsToFirestore(GameModeStats stats) {
    return {
      'matchesPlayed': stats.matchesPlayed,
      'wins': stats.wins,
      'losses': stats.losses,
      'draws': stats.draws,
      'blocksDominated': stats.blocksDominated,
      'blocksLost': stats.blocksLost,
      'totalTimePlayedSeconds': stats.totalTimePlayedSeconds,
      'longestMatchSeconds': stats.longestMatchSeconds,
      'fastestMatchSeconds': stats.fastestMatchSeconds,
      'longestMoveTimeMs': stats.longestMoveTimeMs,
      'fastestMoveTimeMs': stats.fastestMoveTimeMs,
      'currentWinStreak': stats.currentWinStreak,
      'bestWinStreak': stats.bestWinStreak,
      'hatTricks': stats.hatTricks,
      'comebackWins': stats.comebackWins,
      'dominationWins': stats.dominationWins,
      'totalBlocksPerGame': stats.totalBlocksPerGame,
      'quickestWinTurns': stats.quickestWinTurns,
      'longestGame': stats.longestGame,
      'lastWinTimestamp': stats.lastWinTimestamp != null ? Timestamp.fromDate(stats.lastWinTimestamp!) : null,
      'winRate': stats.winRate,
      'averageMatchDuration': stats.averageMatchDuration,
      'averageBlocksPerGame': stats.averageBlocksPerGame,
      'averageBlocksLostPerGame': stats.averageBlocksLostPerGame,
      'dominationRate': stats.dominationRate,
    };
  }

  // Convert Firestore to GameModeStats
  GameModeStats _firestoreToGameModeStats(Map<String, dynamic>? data) {
    if (data == null) return GameModeStats();

    return GameModeStats(
      matchesPlayed: data['matchesPlayed'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      draws: data['draws'] ?? 0,
      blocksDominated: data['blocksDominated'] ?? 0,
      blocksLost: data['blocksLost'] ?? 0,
      totalTimePlayedSeconds: data['totalTimePlayedSeconds'] ?? 0,
      longestMatchSeconds: data['longestMatchSeconds'] ?? 0,
      fastestMatchSeconds: data['fastestMatchSeconds'] ?? 0,
      longestMoveTimeMs: data['longestMoveTimeMs'] ?? 0,
      fastestMoveTimeMs: data['fastestMoveTimeMs'] ?? 0,
      currentWinStreak: data['currentWinStreak'] ?? 0,
      bestWinStreak: data['bestWinStreak'] ?? 0,
      hatTricks: data['hatTricks'] ?? 0,
      comebackWins: data['comebackWins'] ?? 0,
      dominationWins: data['dominationWins'] ?? 0,
      totalBlocksPerGame: (data['totalBlocksPerGame'] ?? 0.0).toDouble(),
      quickestWinTurns: data['quickestWinTurns'] ?? 0,
      longestGame: data['longestGame'] ?? 0,
      lastWinTimestamp: (data['lastWinTimestamp'] as Timestamp?)?.toDate(),
    );
  }
}
