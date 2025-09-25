import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_profile.dart';
import '../models/game_stats.dart';
import '../game/dominate_game.dart';
import 'firebase_auth_service.dart';
import 'firebase_profile_service.dart';
import 'firebase_leaderboard_service.dart';

class ProfileService {
  static const String _currentProfileKey = 'current_player_profile';
  static const String _allProfilesKey = 'all_player_profiles';

  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._();

  ProfileService._();

  PlayerProfile? _currentProfile;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirebaseProfileService _firebaseProfileService = FirebaseProfileService.instance;
  final FirebaseLeaderboardService _leaderboardService = FirebaseLeaderboardService.instance;

  // Animal-based nickname suggestions
  static const List<String> _animalNicknames = ['CyberCat', 'QuantumDog', 'NebulaBear', 'StarFox', 'GalaxyWolf', 'CosmicOwl', 'PlutoPanda', 'OrionTiger', 'AstroPenguin', 'VegaViper', 'SolarShark', 'LunarLion', 'MeteorMouse', 'CometCrab', 'SaturnSeal', 'JupiterJaguar', 'MarsMonkey', 'UranusUnicorn', 'NeptuneNarwhal', 'PlutoParrot'];

  // Initialize service and load current profile
  Future<void> initialize() async {
    try {
      // First try to sign in anonymously if not authenticated
      if (!_authService.isAuthenticated) {
        try {
          await _authService.signInAnonymously();
        } catch (e) {
          // If anonymous sign-in fails, continue with local storage only
          debugPrint('Anonymous sign-in failed: $e');
        }
      }

      // Now check authentication and load profile accordingly
      if (_authService.isAuthenticated) {
        try {
          // Load profile from Firebase
          _currentProfile = await _firebaseProfileService.loadProfile();
        } catch (e) {
          // If Firebase fails, fall back to local storage
          debugPrint('Firebase profile load failed: $e');
          await loadCurrentProfile();
        }
      } else {
        // Load profile from local storage
        await loadCurrentProfile();
      }
    } catch (e) {
      // Continue without loaded profile if initialization fails
      debugPrint('ProfileService initialization failed: $e');
      _currentProfile = null;
    }
  }

  // Get current player profile
  PlayerProfile? get currentProfile => _currentProfile;

  // Check if player is registered
  bool get isPlayerRegistered => _currentProfile?.isRegistered ?? false;

  // Load current profile from storage
  Future<void> loadCurrentProfile() async {
    try {
      // Add a small delay to ensure Flutter is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_currentProfileKey);

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        _currentProfile = PlayerProfile.fromJson(profileData);
      }
    } catch (e) {
      // If SharedPreferences fails, we'll just work without a saved profile
      _currentProfile = null;
    }
  }

  // Save current profile to storage
  Future<void> saveCurrentProfile(PlayerProfile profile) async {
    try {
      _currentProfile = profile;

      if (_authService.isAuthenticated && profile.isRegistered) {
        // Save to Firebase if authenticated and registered
        await _firebaseProfileService.saveProfile(profile);
      } else {
        // Save to local storage for temporary profiles
        await _saveToLocalStorage(profile);
      }
    } catch (e) {
      // Set the profile in memory even if saving fails
      _currentProfile = profile;
      // Don't throw exception, just log the error and continue
    }
  }

  // Save to local storage (for temporary profiles)
  Future<void> _saveToLocalStorage(PlayerProfile profile) async {
    try {
      // Add a small delay to ensure Flutter is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());

      await prefs.setString(_currentProfileKey, profileJson);

      // Also save to all profiles list if registered
      if (profile.isRegistered) {
        await _saveToAllProfiles(profile);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Save profile to all profiles list
  Future<void> _saveToAllProfiles(PlayerProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allProfilesJson = prefs.getString(_allProfilesKey) ?? '[]';
      final List<dynamic> allProfiles = jsonDecode(allProfilesJson);

      // Remove existing profile with same ID
      allProfiles.removeWhere((p) => p['id'] == profile.id);

      // Add updated profile
      allProfiles.add(profile.toJson());

      await prefs.setString(_allProfilesKey, jsonEncode(allProfiles));
    } catch (e) {
      //error handler
    }
  }

  // Create new profile (with Firebase authentication)
  Future<PlayerProfile> createProfile({required String email, required String nickname, required String password, required AvatarType avatarType, String? imagePath, AvatarOption? avatarOption}) async {
    // Create Firebase account first
    final user = await _authService.createAccount(email, password);
    if (user == null) {
      throw Exception('Failed to create Firebase account');
    }

    // Create profile in Firebase
    final profile = await _firebaseProfileService.createProfileForUser(email: email, nickname: nickname, avatarType: avatarType, imagePath: imagePath, avatarOption: avatarOption);

    _currentProfile = profile;
    return profile;
  }

  // Update current profile
  Future<PlayerProfile> updateProfile({String? email, String? nickname, String? password, AvatarType? avatarType, String? imagePath, AvatarOption? avatarOption, bool? isEmailVerified}) async {
    if (_currentProfile == null) {
      throw Exception('No current profile to update');
    }

    if (_authService.isAuthenticated && _currentProfile!.isRegistered) {
      // Update Firebase profile
      if (password != null) {
        await _authService.updatePassword(password);
      }
      if (email != null && email != _currentProfile!.email) {
        await _authService.updateEmail(email);
      }

      final updatedProfile = await _firebaseProfileService.updateProfile(currentProfile: _currentProfile, email: email, nickname: nickname, avatarType: avatarType, imagePath: imagePath, avatarOption: avatarOption, isEmailVerified: isEmailVerified);

      if (updatedProfile != null) {
        _currentProfile = updatedProfile;
        return updatedProfile;
      } else {
        throw Exception('Failed to update Firebase profile');
      }
    } else {
      // Update local profile for temporary users
      String? newPasswordHash;
      String? newSalt;
      if (password != null) {
        newSalt = _generateSalt();
        newPasswordHash = _hashPassword(password, newSalt);
      }

      final updatedProfile = _currentProfile!.copyWith(email: email, nickname: nickname, passwordHash: newPasswordHash, salt: newSalt, avatarType: avatarType, imagePath: imagePath, avatarOption: avatarOption, isEmailVerified: isEmailVerified);

      await saveCurrentProfile(updatedProfile);
      return updatedProfile;
    }
  }

  // Generate temporary profile for unregistered players
  PlayerProfile generateTemporaryProfile() {
    final random = Random();
    final nickname = _animalNicknames[random.nextInt(_animalNicknames.length)];
    final avatarOption = AvatarOption.values[random.nextInt(AvatarOption.values.length)];

    final profile = PlayerProfile.temporary(nickname: nickname, avatarOption: avatarOption);

    _currentProfile = profile;
    return profile;
  }

  // Validate nickname
  String? validateNickname(String nickname) {
    if (nickname.isEmpty) {
      return 'Nickname cannot be empty';
    }
    if (nickname.length < 3) {
      return 'Nickname must be at least 3 characters';
    }
    if (nickname.length > 10) {
      return 'Nickname cannot exceed 10 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(nickname)) {
      return 'Nickname can only contain letters, numbers, hyphens, and underscores';
    }
    return null;
  }

  // Validate email
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Generate random nickname suggestion
  String generateNicknameSuggestion() {
    final random = Random();
    return _animalNicknames[random.nextInt(_animalNicknames.length)];
  }

  // Get all registered profiles
  Future<List<PlayerProfile>> getAllProfiles() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      final allProfilesJson = prefs.getString(_allProfilesKey) ?? '[]';
      final List<dynamic> allProfiles = jsonDecode(allProfilesJson);

      return allProfiles.map((p) => PlayerProfile.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear current profile (logout)
  Future<void> clearCurrentProfile() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentProfileKey);
      _currentProfile = null;
    } catch (e) {
      // Clear from memory even if storage fails
      _currentProfile = null;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final profiles = await getAllProfiles();
    return profiles.any((p) => p.email.toLowerCase() == email.toLowerCase());
  }

  // Ensure current player has a profile
  Future<PlayerProfile> ensureCurrentPlayer() async {
    if (_currentProfile == null) {
      try {
        // First try to sign in anonymously if not authenticated
        if (!_authService.isAuthenticated) {
          await _authService.signInAnonymously();
        }

        // Generate temporary profile
        _currentProfile = generateTemporaryProfile();
      } catch (e) {
        // If Firebase fails, create a local-only temporary profile
        debugPrint('Failed to ensure current player with Firebase: $e');
        _currentProfile = generateTemporaryProfile();
      }
    }
    return _currentProfile!;
  }

  // Validate password
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (password.length > 50) {
      return 'Password cannot exceed 50 characters';
    }
    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(password)) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  // Generate random salt for password hashing
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Hash password with salt
  String _hashPassword(String password, String salt) {
    final saltBytes = base64.decode(salt);
    final passwordBytes = utf8.encode(password);
    final combined = Uint8List.fromList([...saltBytes, ...passwordBytes]);
    final digest = sha256.convert(combined);
    return digest.toString();
  }

  // Login with email and password
  Future<PlayerProfile?> login(String email, String password) async {
    try {
      // Sign in with Firebase
      final user = await _authService.signInWithEmailAndPassword(email, password);
      if (user == null) {
        return null; // Authentication failed
      }

      // Load profile from Firebase
      final profile = await _firebaseProfileService.loadProfile();
      if (profile != null) {
        _currentProfile = profile;
        return profile;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout current user
  Future<void> logout() async {
    await _authService.signOut();
    await clearCurrentProfile();
  }

  // Check if user can login (has registered profile)
  Future<bool> canLogin(String email) async {
    try {
      final profiles = await getAllProfiles();
      return profiles.any((p) => p.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  // Update player stats with match result
  Future<PlayerProfile> updateStats({required GameMode gameMode, required MatchResult result, required int playerBlocks, required int opponentBlocks, required int matchDurationSeconds, required List<int> moveTimes, required int totalTurns, bool wasBehind = false}) async {
    if (_currentProfile == null) {
      throw Exception('No current profile to update stats for');
    }

    if (_authService.isAuthenticated && _currentProfile!.isRegistered) {
      // Update stats in Firebase
      final updatedProfile = await _firebaseProfileService.updateStats(currentProfile: _currentProfile, gameMode: gameMode, result: result, playerBlocks: playerBlocks, opponentBlocks: opponentBlocks, matchDurationSeconds: matchDurationSeconds, moveTimes: moveTimes, totalTurns: totalTurns, wasBehind: wasBehind);

      if (updatedProfile != null) {
        _currentProfile = updatedProfile;
        // Update leaderboard when stats change
        await _updateLeaderboard();
        return updatedProfile;
      } else {
        throw Exception('Failed to update stats in Firebase');
      }
    } else {
      // Update local stats for temporary users
      final updatedStats = _currentProfile!.stats.updateWithMatch(mode: gameMode, result: result, playerBlocks: playerBlocks, opponentBlocks: opponentBlocks, matchDurationSeconds: matchDurationSeconds, moveTimes: moveTimes, totalTurns: totalTurns, wasBehind: wasBehind);

      final updatedProfile = _currentProfile!.copyWith(stats: updatedStats);
      await saveCurrentProfile(updatedProfile);
      return updatedProfile;
    }
  }

  // Get stats for current player
  PlayerStats? get currentPlayerStats => _currentProfile?.stats;

  // Get stats for a specific game mode
  GameModeStats? getStatsForMode(GameMode mode) {
    return _currentProfile?.stats.getStatsForMode(mode);
  }

  // Get total stats across all game modes
  GameModeStats? get totalStats => _currentProfile?.stats.totalStats;

  // Sign in anonymously for temporary play
  Future<void> signInAnonymously() async {
    try {
      await _authService.signInAnonymously();
    } catch (e) {
      // Handle error silently, user can continue without Firebase
    }
  }

  // Convert temporary account to permanent
  Future<PlayerProfile?> convertToPermanentAccount({required String email, required String nickname, required String password, required AvatarType avatarType, String? imagePath, AvatarOption? avatarOption}) async {
    try {
      // Link anonymous account with email/password
      final user = await _authService.linkWithEmailAndPassword(email, password);
      if (user == null) {
        return null;
      }

      // Create permanent profile
      final profile = await _firebaseProfileService.createProfileForUser(email: email, nickname: nickname, avatarType: avatarType, imagePath: imagePath, avatarOption: avatarOption);

      // Migrate stats from current temporary profile if exists
      if (_currentProfile != null && _currentProfile!.stats.totalStats.matchesPlayed > 0) {
        await _firebaseProfileService.updateProfile(stats: _currentProfile!.stats);
      }

      _currentProfile = profile;
      return profile;
    } catch (e) {
      return null;
    }
  }

  // Check if nickname is available (Firebase)
  Future<bool> isNicknameAvailable(String nickname) async {
    if (_authService.isAuthenticated) {
      return await _firebaseProfileService.isNicknameAvailable(nickname);
    } else {
      // For local profiles, check against saved profiles
      final profiles = await getAllProfiles();
      return !profiles.any((p) => p.nickname.toLowerCase() == nickname.toLowerCase());
    }
  }

  // Get top 10 leaderboard entries (much more efficient than old approach)
  Future<List<LeaderboardEntry>> getTop10Leaderboard() async {
    if (!_authService.isAuthenticated) {
      debugPrint('🏆 ProfileService.getTop10Leaderboard: not authenticated');
      return [];
    }

    return await _leaderboardService.getTop10Players();
  }

  // Get current player's position in leaderboard
  Future<PlayerPosition?> getCurrentPlayerPosition() async {
    if (!_authService.isAuthenticated) {
      debugPrint('🏆 ProfileService.getCurrentPlayerPosition: not authenticated');
      return null;
    }

    return await _leaderboardService.getCurrentPlayerPosition();
  }

  // Update leaderboard when player's stats change
  Future<void> _updateLeaderboard() async {
    if (_currentProfile != null && _authService.isAuthenticated && _currentProfile!.isRegistered) {
      try {
        await _leaderboardService.updatePlayerEntry(uid: _currentProfile!.id, nickname: _currentProfile!.nickname, totalWins: _currentProfile!.stats.playerVsAi.wins, avatarOption: _currentProfile!.avatarOption, lastWinTimestamp: _currentProfile!.stats.playerVsAi.lastWinTimestamp);
        debugPrint('🏆 ProfileService: updated leaderboard entry');
      } catch (e) {
        debugPrint('🏆 ProfileService: failed to update leaderboard: $e');
      }
    }
  }

  // Search players by nickname
  Future<List<PlayerProfile>> searchPlayers(String nickname) async {
    if (_authService.isAuthenticated) {
      return await _firebaseProfileService.searchProfilesByNickname(nickname);
    } else {
      return [];
    }
  }
}
