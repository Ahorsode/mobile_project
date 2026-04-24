import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<LeaderboardProvider>().fetchLeaderboard());
  }

  String _getCountryEmoji(String? country) {
    if (country == null) return '🏳️';
    switch (country.toLowerCase()) {
      case 'united states': return '🇺🇸';
      case 'united kingdom': return '🇬🇧';
      case 'canada': return '🇨🇦';
      case 'australia': return '🇦🇺';
      case 'germany': return '🇩🇪';
      case 'france': return '🇫🇷';
      case 'india': return '🇮🇳';
      case 'brazil': return '🇧🇷';
      case 'nigeria': return '🇳🇬';
      case 'japan': return '🇯🇵';
      default: return '🏳️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Hall of Heroes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.topUsers.isEmpty) {
            return const Center(child: Text('No heroes found yet...'));
          }

          final top3 = provider.topUsers.take(3).toList();
          final others = provider.topUsers.skip(3).toList();

          return Column(
            children: [
              // Top 3 Podium
              Container(
                height: 240,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (top3.length > 1) _buildTopCard(top3[1], 2, Colors.grey[400]!, 180),
                    if (top3.isNotEmpty) _buildTopCard(top3[0], 1, Colors.amber, 220),
                    if (top3.length > 2) _buildTopCard(top3[2], 3, Colors.brown[400]!, 160),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // List for 4-50
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final user = others[index];
                    final rank = index + 4;
                    return _buildRankTile(user, rank);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopCard(Map<String, dynamic> user, int rank, Color color, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: Text(
            user['username']?[0].toUpperCase() ?? '?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user['username'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          '${user['xp']} XP',
          style: TextStyle(color: color, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height - 100,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankTile(Map<String, dynamic> user, int rank) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          child: Text('#$rank', style: const TextStyle(color: Colors.blueAccent)),
        ),
        title: Row(
          children: [
            Text(_getCountryEmoji(user['country'])),
            const SizedBox(width: 8),
            Text(user['username'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Text(
          '${user['xp']} XP',
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
