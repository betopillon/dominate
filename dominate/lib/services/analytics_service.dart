import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _trackingAllowed = false;
  bool _initialized = false;

  FirebaseAnalytics? get analytics => _analytics;
  bool get trackingAllowed => _trackingAllowed;
  bool get initialized => _initialized;

  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      debugPrint('📊 Initializing AnalyticsService...');

      // Initialize Firebase Analytics
      _analytics = FirebaseAnalytics.instance;

      // Check if we can track (iOS only, Android doesn't need ATT)
      await _checkTrackingPermission();

      _initialized = true;
      debugPrint('📊 AnalyticsService initialized successfully. Tracking allowed: $_trackingAllowed');
    } catch (e) {
      debugPrint('📊 AnalyticsService initialization failed: $e');
      _initialized = false;
    }
  }

  /// Check and request tracking permission
  Future<void> _checkTrackingPermission() async {
    if (!_initialized || _analytics == null) return;

    try {
      // For iOS, check App Tracking Transparency status
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;

      switch (status) {
        case TrackingStatus.authorized:
          _trackingAllowed = true;
          await _analytics!.setAnalyticsCollectionEnabled(true);
          debugPrint('📊 Tracking authorized by user');
          break;
        case TrackingStatus.denied:
        case TrackingStatus.restricted:
          _trackingAllowed = false;
          await _analytics!.setAnalyticsCollectionEnabled(false);
          debugPrint('📊 Tracking denied/restricted by user');
          break;
        case TrackingStatus.notDetermined:
          // Will be handled by requestTrackingPermission
          _trackingAllowed = false;
          await _analytics!.setAnalyticsCollectionEnabled(false);
          debugPrint('📊 Tracking permission not determined yet');
          break;
      }
    } catch (e) {
      debugPrint('📊 Error checking tracking permission: $e');
      // Fallback: assume tracking is allowed (for Android or if ATT fails)
      _trackingAllowed = true;
      if (_analytics != null) {
        await _analytics!.setAnalyticsCollectionEnabled(true);
      }
    }
  }

  /// Request tracking permission from user (iOS only)
  Future<bool> requestTrackingPermission() async {
    if (!_initialized || _analytics == null) return false;

    try {
      debugPrint('📊 Requesting tracking permission...');

      final status = await AppTrackingTransparency.requestTrackingAuthorization();

      switch (status) {
        case TrackingStatus.authorized:
          _trackingAllowed = true;
          await _analytics!.setAnalyticsCollectionEnabled(true);
          debugPrint('📊 User granted tracking permission');
          return true;
        case TrackingStatus.denied:
        case TrackingStatus.restricted:
          _trackingAllowed = false;
          await _analytics!.setAnalyticsCollectionEnabled(false);
          debugPrint('📊 User denied tracking permission');
          return false;
        case TrackingStatus.notDetermined:
          _trackingAllowed = false;
          await _analytics!.setAnalyticsCollectionEnabled(false);
          debugPrint('📊 Tracking permission still not determined');
          return false;
      }
    } catch (e) {
      debugPrint('📊 Error requesting tracking permission: $e');
      return false;
    }
  }

  /// Log a custom event (only if tracking is allowed)
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_initialized || !_trackingAllowed || _analytics == null) {
      debugPrint('📊 Skipping event "$name" - tracking not allowed or not initialized');
      return;
    }

    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
      debugPrint('📊 Logged event: $name ${parameters != null ? 'with parameters: $parameters' : ''}');
    } catch (e) {
      debugPrint('📊 Error logging event "$name": $e');
    }
  }

  /// Log app open event
  Future<void> logAppOpen() async {
    await logEvent('app_open');
  }

  /// Log game start event
  Future<void> logGameStart({
    required String gameMode,
    required int playerCount,
  }) async {
    await logEvent('game_start', parameters: {
      'game_mode': gameMode,
      'player_count': playerCount,
    });
  }

  /// Log game end event
  Future<void> logGameEnd({
    required String gameMode,
    required int playerCount,
    required String result, // 'win', 'lose', 'draw'
    required int duration, // in seconds
    required int finalScore,
  }) async {
    await logEvent('game_end', parameters: {
      'game_mode': gameMode,
      'player_count': playerCount,
      'result': result,
      'duration': duration,
      'final_score': finalScore,
    });
  }

  /// Log user action event
  Future<void> logUserAction(String action, {Map<String, Object>? parameters}) async {
    await logEvent('user_action', parameters: {
      'action': action,
      ...?parameters,
    });
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    if (!_initialized || !_trackingAllowed || _analytics == null) return;

    try {
      await _analytics!.logScreenView(screenName: screenName);
      debugPrint('📊 Logged screen view: $screenName');
    } catch (e) {
      debugPrint('📊 Error logging screen view "$screenName": $e');
    }
  }

  /// Set user property (only if tracking is allowed)
  Future<void> setUserProperty(String name, String? value) async {
    if (!_initialized || !_trackingAllowed || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      debugPrint('📊 Set user property: $name = $value');
    } catch (e) {
      debugPrint('📊 Error setting user property "$name": $e');
    }
  }

  /// Set user ID (only if tracking is allowed)
  Future<void> setUserId(String? userId) async {
    if (!_initialized || !_trackingAllowed || _analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
      debugPrint('📊 Set user ID: $userId');
    } catch (e) {
      debugPrint('📊 Error setting user ID: $e');
    }
  }
}