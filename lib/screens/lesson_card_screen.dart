import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/lesson.dart';
import '../providers/academy_provider.dart';

class LessonCardScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonCardScreen({super.key, required this.lesson});

  @override
  State<LessonCardScreen> createState() => _LessonCardScreenState();
}

class _LessonCardScreenState extends State<LessonCardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _selectedOption;
  bool _isCorrect = false;
  List<int> _shuffledIndices = [];

  @override
  void initState() {
    super.initState();
    if (widget.lesson.quiz.isNotEmpty) {
      _shuffledIndices = List.generate(
        widget.lesson.quiz[0].options.length,
        (index) => index,
      );
      _shuffledIndices.shuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildTheoryScreen(),
                _buildCodeScreen(),
                _buildQuizScreen(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentPage >= index
                    ? Colors.blueAccent
                    : Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTheoryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CONCEPT",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: widget.lesson.theory,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "THE LOGIC",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.lesson.logic,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CODE DISCOVERY",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              widget.lesson.codeDiscovery,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 16,
                color: Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/editor',
                  arguments: {
                    'initialCode': widget.lesson.tryCode,
                    'fileName':
                        'practice_${widget.lesson.id.replaceAll('.', '_')}.py',
                  },
                );
              },
              icon: const Icon(Icons.code),
              label: const Text("TRY IN WORKPLACE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "THE QUEST",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.lesson.quest,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    if (widget.lesson.quiz.isEmpty) {
      return const Center(child: Text("No quiz available for this lesson."));
    }

    final quiz = widget
        .lesson
        .quiz[0]; // Simplified to handle one question per lesson for UI demo

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CHECKPOINT",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            quiz.question,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ...List.generate(_shuffledIndices.length, (index) {
            final originalIndex = _shuffledIndices[index];
            bool isSelected = _selectedOption == index;
            bool isCorrectOption = originalIndex == quiz.correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedOption = index;
                    _isCorrect = isCorrectOption;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isCorrectOption
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2))
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isCorrectOption
                                ? Colors.greenAccent
                                : Colors.redAccent)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${String.fromCharCode(65 + index)}) ${quiz.options[originalIndex]}",
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          isCorrectOption ? Icons.check_circle : Icons.cancel,
                          color: isCorrectOption
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text("PREVIOUS"),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                if (_selectedOption != null) {
                  _completeLesson();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select an answer first!"),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_currentPage < 2 ? "NEXT" : "FINISH"),
          ),
        ],
      ),
    );
  }

  void _completeLesson() {
    final academy = Provider.of<AcademyProvider>(context, listen: false);
    final score = _isCorrect ? 1.0 : 0.0; // Simplified score
    academy.completeLesson(widget.lesson.id, score);
    Navigator.pop(context);

    String message = _isCorrect
        ? "Perfect! Lesson Mastered."
        : "Completed! Review the concepts and try again.";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _isCorrect ? Colors.green : Colors.orange,
      ),
    );
  }
}
