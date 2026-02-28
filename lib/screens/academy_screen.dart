import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academy_provider.dart';
import 'lesson_card_screen.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academy = Provider.of<AcademyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("PyQuest Academy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: academy.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: academy.tiers.length,
              itemBuilder: (context, index) {
                final tier = academy.tiers[index];
                final isUnlocked = academy.isTierUnlocked(index);
                final progress = academy.getTierProgress(index);
                final mastery = academy.getTierMastery(index);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTierHeader(tier.title, isUnlocked, progress, mastery),
                    const SizedBox(height: 16),
                    if (isUnlocked)
                      _buildLessonGrid(context, tier.lessons, academy)
                    else
                      _buildLockedPlaceholder(),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTierHeader(String title, bool isUnlocked, double progress, double mastery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? Colors.blueAccent.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUnlocked ? Icons.auto_awesome : Icons.lock,
                color: isUnlocked ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Progress", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.black26,
                      color: Colors.blueAccent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Mastery", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: mastery,
                      backgroundColor: Colors.black26,
                      color: mastery >= 0.8 ? Colors.greenAccent : Colors.orangeAccent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonGrid(BuildContext context, List lessons, AcademyProvider academy) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final isCompleted = academy.isLessonCompleted(lesson.id);
        final score = academy.getLessonScore(lesson.id);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialApp.router(
                builder: (context, child) => LessonCardScreen(lesson: lesson),
              ).routeInformationParser as RouteSettings, // Incorrect navigation pattern fix
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isCompleted)
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
                    else
                      const Icon(Icons.play_circle_outline, color: Colors.blueAccent, size: 20),
                    if (isCompleted)
                      Text(
                        "${(score * 100).toInt()}%",
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          "Complete the previous Tier to unlock",
          style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
