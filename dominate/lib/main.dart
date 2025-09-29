import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'game/dominate_game.dart';
import 'models/player.dart';
import 'screens/main_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'widgets/space_background.dart';
import 'services/profile_service.dart';
import 'services/audio_service.dart';
import 'services/analytics_service.dart';

void main() async {
  // Wrap everything in try-catch to prevent app crashes during initialization
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with platform-specific options
    try {
      print('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔥 Firebase initialized successfully');
    } catch (e) {
      print('🔥 Firebase initialization failed: $e');
      print('🔥 App will continue with local-only functionality');
      // Continue without Firebase - app should still work locally
    }

    // Initialize profile service
    try {
      print('👤 Initializing ProfileService...');
      await ProfileService.instance.initialize();
      print('👤 ProfileService initialized successfully');
    } catch (e) {
      print('👤 ProfileService initialization failed: $e');
      // Profile service has its own error handling, continue anyway
    }

    // Initialize analytics service
    try {
      print('📊 Initializing AnalyticsService...');
      await AnalyticsService.instance.initialize();
      print('📊 AnalyticsService initialized successfully');
    } catch (e) {
      print('📊 AnalyticsService initialization failed: $e');
      // Analytics service failure shouldn't prevent app from running
    }

    // Initialize audio service
    try {
      print('🎵 Initializing AudioService...');
      await AudioService.instance.initialize();
      print('🎵 AudioService initialized successfully');
    } catch (e) {
      print('🎵 AudioService initialization failed: $e');
      // Audio service failure shouldn't prevent app from running
    }

    // Lock to portrait orientation for mobile
    try {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      print('📱 Portrait orientation set');
    } catch (e) {
      print('📱 Orientation setting failed: $e');
      // Orientation failure is not critical
    }

    print('✅ App initialization completed, starting app...');
    runApp(const DominateApp());

  } catch (e) {
    print('💥 CRITICAL: App initialization failed completely: $e');
    // Even if everything fails, try to start the app with minimal functionality
    runApp(const DominateApp());
  }
}

class DominateApp extends StatefulWidget {
  const DominateApp({super.key});

  @override
  State<DominateApp> createState() => _DominateAppState();
}

class _DominateAppState extends State<DominateApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize analytics and request tracking permission
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeAnalytics();
    });

    // Start background music after a short delay to ensure everything is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        AudioService.instance.startBackgroundMusic();
      } catch (e) {
        print('🎵 Failed to start background music: $e');
        // Music failure shouldn't affect app functionality
      }
    });
  }

  Future<void> _initializeAnalytics() async {
    try {
      // Log app open
      await AnalyticsService.instance.logAppOpen();

      // Request tracking permission (iOS only)
      await AnalyticsService.instance.requestTrackingPermission();
    } catch (e) {
      print('📊 Failed to initialize analytics: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    try {
      AudioService.instance.onAppLifecycleStateChanged(state);
    } catch (e) {
      print('🎵 Audio lifecycle state change failed: $e');
      // Audio lifecycle errors shouldn't crash the app
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dominate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Futura',
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SpaceBackground(child: const MainScreen()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameMode gameMode;

  const GameScreen({super.key, required this.gameMode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  DominateGame? game;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _ensurePlayerProfile();
  }

  Future<void> _ensurePlayerProfile() async {
    // Ensure current player has a profile (either existing or temporary)
    await ProfileService.instance.ensureCurrentPlayer();
    // Create game immediately and start with the passed game mode
    _startGame(widget.gameMode);
  }

  void _startGame(GameMode mode) {
    setState(() {
      game = DominateGame();
      _isGameOver = false;
    });

    // Set up game over callback
    game!.onGameOver = () {
      setState(() {
        _isGameOver = true;
      });
      _logGameEnd();
    };

    // Start the game after widget is built
    Future.delayed(const Duration(milliseconds: 100), () {
      game!.startGame(mode);
      _logGameStart(mode);
    });
  }

  void _logGameStart(GameMode mode) {
    try {
      final playerCount = game?.gamePlayers.players.length ?? 2;
      AnalyticsService.instance.logGameStart(
        gameMode: mode.toString().split('.').last,
        playerCount: playerCount,
      );
    } catch (e) {
      print('📊 Failed to log game start: $e');
    }
  }

  void _logGameEnd() {
    try {
      if (game == null) return;

      final players = game!.gamePlayers.players;
      final winners = game!.gamePlayers.getWinners();
      final currentPlayer = players.first; // Use first player as reference

      String result;
      if (winners.isEmpty) {
        result = 'draw';
      } else if (winners.contains(currentPlayer)) {
        result = 'win';
      } else {
        result = 'lose';
      }

      // Calculate game duration (approximate)
      final duration = 300; // Placeholder - you might want to track actual duration

      AnalyticsService.instance.logGameEnd(
        gameMode: widget.gameMode.toString().split('.').last,
        playerCount: players.length,
        result: result,
        duration: duration,
        finalScore: currentPlayer.score,
      );
    } catch (e) {
      print('📊 Failed to log game end: $e');
    }
  }

  void _backToMenu() {
    Navigator.pop(context);
  }

  void _showHowToPlay() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const HowToPlayScreen()));
  }

  void _playAgain() {
    _startGame(widget.gameMode);
  }

  String _getWinnerText(List<Player> winners) {
    if (winners.isEmpty) {
      return 'It\'s a Draw! No winners this time.';
    } else if (winners.length == 1) {
      return 'Winner: ${winners.first.name}';
    } else {
      // Multiple winners with same score
      return 'It\'s a Draw! Winners: ${winners.map((w) => w.name).join(', ')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          game != null
              ? Stack(
                children: [
                  // Game board - full screen
                  GameWidget(game: game!),
                  // Top overlay - compact game info
                  Positioned(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, child: _buildCompactGameInfo()),
                  // Bottom overlay - control button
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                    child: StreamBuilder<int>(
                      stream: Stream.periodic(const Duration(milliseconds: 100), (i) => i),
                      builder: (context, snapshot) {
                        return _buildControlButtons();
                      },
                    ),
                  ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCompactGameInfo() {
    if (game == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.5), width: 1)),
        child: const Text('Starting game...', style: TextStyle(fontFamily: 'Futura', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
      );
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 100), (i) => i),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.6), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)]),
          child: _buildGameState(),
        );
      },
    );
  }

  Widget _buildGameState() {
    if (game!.gameState == GameState.playing) {
      final currentPlayer = game!.gamePlayers.currentPlayer;
      final players = game!.gamePlayers.players;

      return Column(
        children: [
          // Current player and timer row
          Row(
            children: [
              // Current player indicator
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentPlayer.color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: game!.hasConsecutiveMove ? Colors.amber : currentPlayer.color, width: game!.hasConsecutiveMove ? 3 : 2),
                    boxShadow: game!.hasConsecutiveMove ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: currentPlayer.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(currentPlayer.name, style: const TextStyle(fontFamily: 'Futura', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (game!.hasConsecutiveMove) ...[const SizedBox(width: 6), const Icon(Icons.flash_on, color: Colors.amber, size: 16)],
                    ],
                  ),
                ),
              ),
              // Timer for human players
              if (currentPlayer.type == PlayerType.human) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: game!.remainingMoveTime <= 10 ? Colors.red.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: game!.remainingMoveTime <= 10 ? Colors.red : Colors.orange, width: 2)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.timer, color: game!.remainingMoveTime <= 10 ? Colors.red : Colors.orange, size: 14), const SizedBox(width: 4), Text('${game!.remainingMoveTime}s', style: TextStyle(fontFamily: 'Futura', fontSize: 12, fontWeight: FontWeight.bold, color: game!.remainingMoveTime <= 10 ? Colors.red : Colors.orange))]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                players.map((player) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: player.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: player.color.withValues(alpha: 0.5), width: 1)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: player.color, shape: BoxShape.circle)), const SizedBox(width: 4), Text('${player.score}', style: const TextStyle(fontFamily: 'Futura', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))]),
                  );
                }).toList(),
          ),
        ],
      );
    } else if (game!.gameState == GameState.gameOver) {
      final winners = game!.gamePlayers.getWinners();
      final players = game!.gamePlayers.players;

      return Column(
        children: [
          // Game Over Title
          ShaderMask(
            shaderCallback:
                (bounds) => const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 94, 63, 4),
                    Color(0xFFFFD700), // Gold
                    Color.fromARGB(255, 94, 63, 4), // Orange
                  ],
                ).createShader(bounds),
            child: const Text('GAME OVER', style: TextStyle(fontFamily: 'Futura', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
          ),
          const SizedBox(height: 8),
          // Winner announcement
          Text(_getWinnerText(winners), style: const TextStyle(fontFamily: 'Futura', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          // Final scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                players.map((player) {
                  final isWinner = winners.contains(player);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isWinner ? Colors.amber.withValues(alpha: 0.3) : player.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: isWinner ? Colors.amber : player.color, width: isWinner ? 2 : 1)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 16, height: 16, decoration: BoxDecoration(color: player.color, shape: BoxShape.circle, border: isWinner ? Border.all(color: Colors.amber, width: 2) : null)),
                        const SizedBox(width: 6),
                        Text('${player.score}', style: TextStyle(fontFamily: 'Futura', fontSize: 16, fontWeight: FontWeight.bold, color: isWinner ? Colors.amber : Colors.white)),
                        if (isWinner) ...[const SizedBox(width: 4), const Icon(Icons.emoji_events, color: Colors.amber, size: 16)],
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      );
    }

    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: const Text('Welcome to Dominate!\nPlace blocks and dominate the board!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Futura', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)));
  }

  Widget _buildControlButtons() {
    if (game?.gameState == GameState.gameOver || _isGameOver) {
      // Game Over: Show Play Again and Back to Menu buttons
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play Again Button
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _playAgain(),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh, color: Colors.green, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Play Again',
                          style: TextStyle(
                            fontFamily: 'Futura',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Back to Menu Button
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _backToMenu,
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Back to Menu',
                          style: TextStyle(
                            fontFamily: 'Futura',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // During Game: Show Back to Menu and Help buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back to Menu Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.red.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: InkWell(
              onTap: _backToMenu,
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Back to Menu',
                    style: TextStyle(
                      fontFamily: 'Futura',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Help Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: InkWell(
              onTap: _showHowToPlay,
              borderRadius: BorderRadius.circular(24),
              child: const Icon(Icons.help_outline, color: Color(0xFF00D4FF), size: 24),
            ),
          ),
        ],
      );
    }
  }
}
