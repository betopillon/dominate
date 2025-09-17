import 'package:flutter/material.dart';
import '../main.dart';
import '../game/dominate_game.dart';
import '../widgets/space_transition.dart';

class SelectModeScreen extends StatelessWidget {
  const SelectModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF00D4FF), // Cyan
                  Color(0xFF5A67D8), // Purple
                ],
              ).createShader(bounds),
          child: const Text('SELECT MISSION', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.5), width: 1), boxShadow: [BoxShadow(color: const Color(0xFF5A67D8).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2)]),
                child: const Text('Choose Your Battle', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              const Text('Select your conquest strategy:', style: TextStyle(fontSize: 18, color: Colors.white70, letterSpacing: 1)),
              const SizedBox(height: 24),
              _buildModeButton(context: context, title: '1 vs Machine', subtitle: 'Challenge the AI', icon: Icons.smart_toy, color: Colors.blue, gameMode: GameMode.playerVsAi),
              const SizedBox(height: 12),
              _buildModeButton(context: context, title: '1 vs 1', subtitle: 'Two players local', icon: Icons.people, color: Colors.green, gameMode: GameMode.oneVsOne),
              const SizedBox(height: 12),
              _buildModeButton(context: context, title: '1 vs 2', subtitle: 'Three players battle', icon: Icons.group, color: Colors.orange, gameMode: GameMode.oneVsTwo),
              const SizedBox(height: 12),
              _buildModeButton(context: context, title: '1 vs 3', subtitle: 'Four players chaos', icon: Icons.groups, color: Colors.purple, gameMode: GameMode.oneVsThree),
              const SizedBox(height: 12),
              _buildModeButton(context: context, title: 'Custom', subtitle: 'Create custom rules', icon: Icons.tune, color: Colors.grey, gameMode: null, isPlaceholder: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({required BuildContext context, required String title, required String subtitle, required IconData icon, required Color color, GameMode? gameMode, bool isPlaceholder = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPlaceholder ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.6), width: 1),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isPlaceholder ? [Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.3)] : [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.2)]),
        boxShadow: [BoxShadow(color: isPlaceholder ? Colors.grey.withValues(alpha: 0.1) : color.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              isPlaceholder
                  ? () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Coming soon!', style: TextStyle(color: Colors.white)), backgroundColor: color.withValues(alpha: 0.8), duration: const Duration(seconds: 1)));
                  }
                  : () {
                    Navigator.of(context).push(SpaceTransition(child: GameScreen(gameMode: gameMode!)));
                  },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPlaceholder ? Colors.grey.withValues(alpha: 0.2) : color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isPlaceholder ? Colors.grey.withValues(alpha: 0.4) : color.withValues(alpha: 0.6), width: 1),
                    boxShadow: [BoxShadow(color: isPlaceholder ? Colors.grey.withValues(alpha: 0.1) : color.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)],
                  ),
                  child: Icon(icon, size: 28, color: isPlaceholder ? Colors.white60 : Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isPlaceholder ? Colors.white60 : Colors.white, letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(subtitle, style: TextStyle(fontSize: 12, color: isPlaceholder ? Colors.white38 : Colors.white.withValues(alpha: 0.7), letterSpacing: 0.3), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Icon(isPlaceholder ? Icons.lock : Icons.rocket_launch, color: isPlaceholder ? Colors.white38 : Colors.white.withValues(alpha: 0.7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
