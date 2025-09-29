import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'select_mode_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../widgets/space_transition.dart';
import '../widgets/space_background.dart';
import 'leaderboard_screen.dart';
import '../services/analytics_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  @override
  void initState() {
    super.initState();
    // Log screen view
    AnalyticsService.instance.logScreenView('main_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, centerTitle: true, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32.0, 120.0, 32.0, 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game logo
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: Image.asset(
                  'assets/dominate_logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to text if image is not found
                    return ShaderMask(
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF00D4FF), // Cyan
                              Color(0xFF5A67D8), // Purple
                              Color(0xFFED8936), // Orange
                            ],
                          ).createShader(bounds),
                      child: const Text('DOMINATE', style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 6)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              _buildMenuButton(
                title: 'Play',
                subtitle: 'Start a new game',
                icon: Icons.play_arrow,
                color: Colors.green,
                onPressed: () {
                  Navigator.of(context).push(SpaceTransition(child: SpaceBackground(child: const SelectModeScreen())));
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                title: 'Settings',
                subtitle: 'Configure game options',
                icon: Icons.settings,
                color: Colors.blue,
                onPressed: () {
                  Navigator.of(context).push(SpaceTransition(child: SpaceBackground(child: const SettingsScreen())));
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                title: 'Stats',
                subtitle: 'View your game statistics',
                icon: Icons.bar_chart,
                color: Colors.orange,
                onPressed: () {
                  Navigator.of(context).push(SpaceTransition(child: SpaceBackground(child: const StatsScreen())));
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                title: 'Leaderboard',
                subtitle: 'Global rankings',
                icon: Icons.leaderboard,
                color: Colors.cyan,
                onPressed: _showLeaderboard,
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                title: 'Quit',
                subtitle: 'Exit the game',
                icon: Icons.exit_to_app,
                color: Colors.red,
                onPressed: _showQuitConfirmation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.2)]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.5), width: 1)), child: Icon(icon, size: 28, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showLeaderboard() {
    Navigator.of(context).push(
      SpaceTransition(
        child: SpaceBackground(
          child: const LeaderboardScreen(),
        ),
      ),
    );
  }

  void _showQuitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                'Quit Game?',
                style: TextStyle(
                  fontFamily: 'Futura',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to exit the game?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.7),
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Quit'),
            ),
          ],
        );
      },
    );
  }

}
