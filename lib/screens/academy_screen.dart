import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/academy_provider.dart';
import '../services/experience_manager.dart';
import 'lesson_card_screen.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academy = Provider.of<AcademyProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: academy.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildMapContent(context, academy),
                _buildProfileOverlay(academy),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileOverlay(AcademyProvider academy) {
    final progress = ExperienceManager.calculateLevelProgress(academy.totalXP);
    final title = ExperienceManager.getLevelTitle(academy.currentLevel);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Level ${academy.currentLevel} • $title",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.black26,
                        color: Colors.blueAccent,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "XP",
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
                  Text(
                    "${academy.totalXP}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent(BuildContext context, AcademyProvider academy) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 120, bottom: 40),
      itemCount: academy.tiers.length,
      itemBuilder: (context, tIndex) {
        final tier = academy.tiers[tIndex];
        final isUnlocked = academy.isTierUnlocked(tIndex);

        return Column(
          children: [
            _buildTierSectionHeader(tier.title, isUnlocked),
            ...tier.lessons.asMap().entries.map((entry) {
              int lIndex = entry.key;
              final lesson = entry.value;
              bool isLevelUnlocked =
                  isUnlocked; // For simplicity, all lessons in tier are visible if tier is unlocked
              bool isCompleted = academy.isLessonCompleted(lesson.id);

              // Zig-zag pattern
              double alignment = lIndex % 2 == 0 ? -0.5 : 0.5;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Align(
                  alignment: Alignment(alignment, 0),
                  child: _buildQuestNode(
                    context,
                    academy,
                    lesson,
                    isLevelUnlocked,
                    isCompleted,
                  ),
                ),
              );
            }).toList(),
            if (tIndex < academy.tiers.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Icon(
                  Icons.keyboard_double_arrow_down,
                  color: Colors.white24,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTierSectionHeader(String title, bool isUnlocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.blue.withOpacity(0.1) : Colors.black12,
      ),
      child: Center(
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: isUnlocked ? Colors.blueAccent : Colors.white24,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestNode(
    BuildContext context,
    AcademyProvider academy,
    dynamic lesson,
    bool isUnlocked,
    bool isCompleted,
  ) {
    bool isBoss =
        lesson.id.contains("4.2") ||
        lesson.id.contains("9.3") ||
        lesson.id.contains("14.3");

    return InkWell(
      onTap: isUnlocked ? () => _navigateToLesson(context, lesson) : null,
      child: Column(
        children: [
          Container(
            width: isBoss ? 90 : 70,
            height: isBoss ? 90 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !isUnlocked
                  ? Colors.white10
                  : (isCompleted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2)),
              border: Border.all(
                color: !isUnlocked
                    ? Colors.white10
                    : (isCompleted ? Colors.greenAccent : Colors.blueAccent),
                width: 3,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color:
                            (isCompleted
                                    ? Colors.greenAccent
                                    : Colors.blueAccent)
                                .withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                isBoss
                    ? (isUnlocked ? Icons.security : Icons.lock)
                    : (isUnlocked
                          ? (isCompleted
                                ? Icons.check
                                : Icons.local_fire_department)
                          : Icons.lock),
                color: isUnlocked
                    ? (isCompleted ? Colors.greenAccent : Colors.blueAccent)
                    : Colors.white24,
                size: isBoss ? 40 : 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBoss ? "BOSS: ${lesson.title}" : lesson.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.white : Colors.white24,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToLesson(BuildContext context, dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LessonCardScreen(lesson: lesson)),
    );
  }
}
