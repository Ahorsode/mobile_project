import 'package:flutter/material.dart';
import '../widgets/tactile_button.dart';
import '../widgets/world_engine_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
          const WorldEngineBackground(),
          
          // Main UI Layer
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.8),
                  const Color(0xFF0F172A).withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "PyQuest",
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: Colors.blueAccent, blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "NEO-PYTHON ADVENTURE",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueAccent.withValues(alpha: 0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 60),
                
                TactileButton(
                  onPressed: () => Navigator.pushNamed(context, '/editor'),
                  baseColor: Colors.blueAccent,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.terminal, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "WORKSPACE",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TactileButton(
                  onPressed: () => Navigator.pushNamed(context, '/quest'),
                  baseColor: const Color(0xFF334155),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "QUESTRIA MAP",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallTactile(context, Icons.leaderboard, "/leaderboard"),
                    const SizedBox(width: 24),
                    _buildSmallTactile(context, Icons.school, "/academy"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        child: const Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  Widget _buildSmallTactile(BuildContext context, IconData icon, String route) {
    return TactileButton(
      width: 80,
      height: 80,
      baseColor: const Color(0xFF1E293B),
      onPressed: () => Navigator.pushNamed(context, route),
      child: Icon(icon, color: Colors.blueAccent, size: 32),
    );
  }
}
