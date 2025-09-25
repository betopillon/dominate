import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static const String _musicEnabledKey = 'music_enabled';
  static const String _musicVolumeKey = 'music_volume';

  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();

  AudioService._();

  bool _isMusicEnabled = true;
  double _musicVolume = 0.7;
  bool _isInitialized = false;
  bool _isPlaying = false;

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  double get musicVolume => _musicVolume;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;

  // Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load settings from shared preferences
      await _loadSettings();

      // Configure flame audio volume
      // Note: flame_audio volume is set when playing

      _isInitialized = true;
      debugPrint('🎵 AudioService initialized with flame_audio');
    } catch (e) {
      debugPrint('🎵 Error initializing AudioService: $e');
    }
  }

  // Load audio settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.7;

      debugPrint('🎵 Loaded settings: enabled=$_isMusicEnabled, volume=$_musicVolume');
    } catch (e) {
      debugPrint('🎵 Error loading audio settings: $e');
      // Use defaults if loading fails
      _isMusicEnabled = true;
      _musicVolume = 0.7;
    }
  }

  // Save audio settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicEnabledKey, _isMusicEnabled);
      await prefs.setDouble(_musicVolumeKey, _musicVolume);

      debugPrint('🎵 Saved settings: enabled=$_isMusicEnabled, volume=$_musicVolume');
    } catch (e) {
      debugPrint('🎵 Error saving audio settings: $e');
    }
  }

  // Start background music
  Future<void> startBackgroundMusic() async {
    if (!_isInitialized) {
      debugPrint('🎵 AudioService not initialized, cannot start music');
      return;
    }

    if (!_isMusicEnabled) {
      debugPrint('🎵 Music is disabled, not starting');
      return;
    }

    try {
      // Stop any currently playing audio
      await stopBackgroundMusic();

      // Play the background music using flame_audio with volume
      await FlameAudio.bgm.play('bg_loop.wav', volume: _musicVolume);
      _isPlaying = true;
      debugPrint('🎵 Background music started with flame_audio');
    } catch (e) {
      debugPrint('🎵 Error starting background music: $e');
      _isPlaying = false;
    }
  }

  // Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await FlameAudio.bgm.stop();
      _isPlaying = false;
      debugPrint('🎵 Background music stopped');
    } catch (e) {
      debugPrint('🎵 Error stopping background music: $e');
    }
  }

  // Pause background music
  Future<void> pauseBackgroundMusic() async {
    try {
      await FlameAudio.bgm.pause();
      debugPrint('🎵 Background music paused');
    } catch (e) {
      debugPrint('🎵 Error pausing background music: $e');
    }
  }

  // Resume background music
  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicEnabled) return;

    try {
      await FlameAudio.bgm.resume();
      debugPrint('🎵 Background music resumed');
    } catch (e) {
      debugPrint('🎵 Error resuming background music: $e');
    }
  }

  // Toggle music on/off
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    await _saveSettings();

    if (_isMusicEnabled) {
      await startBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }

    debugPrint('🎵 Music toggled: $_isMusicEnabled');
  }

  // Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();

    // Restart audio with new volume if playing
    if (_isInitialized && _isPlaying && _isMusicEnabled) {
      await startBackgroundMusic();
    }

    debugPrint('🎵 Music volume set to: $_musicVolume');
  }

  // Set music enabled state
  Future<void> setMusicEnabled(bool enabled) async {
    if (_isMusicEnabled == enabled) return;

    _isMusicEnabled = enabled;
    await _saveSettings();

    if (_isMusicEnabled) {
      await startBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }

    debugPrint('🎵 Music enabled set to: $_isMusicEnabled');
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await stopBackgroundMusic();
      debugPrint('🎵 AudioService disposed');
    } catch (e) {
      debugPrint('🎵 Error disposing AudioService: $e');
    }
  }

  // Handle app lifecycle changes
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        pauseBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
        if (_isMusicEnabled) {
          resumeBackgroundMusic();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
