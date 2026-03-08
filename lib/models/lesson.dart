class Tier {
  final String title;
  final List<Lesson> lessons;

  Tier({required this.title, required this.lessons});

  factory Tier.fromJson(Map<String, dynamic> json) {
    return Tier(
      title: json['title'],
      lessons: (json['lessons'] as List)
          .map((l) => Lesson.fromJson(l))
          .toList(),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String theory;
  final String logic;
  final String codeDiscovery;
  final String tryCode;
  final String quest;
  final List<QuizQuestion> quiz;

  Lesson({
    required this.id,
    required this.title,
    required this.theory,
    required this.logic,
    required this.codeDiscovery,
    required this.tryCode,
    required this.quest,
    required this.quiz,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      theory: json['theory'] ?? '',
      logic: json['logic'] ?? '',
      codeDiscovery: json['codeDiscovery'] ?? '',
      tryCode: json['tryCode'] ?? json['codeDiscovery'] ?? '',
      quest: json['quest'] ?? '',
      quiz: (json['quiz'] as List? ?? [])
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
    );
  }
}
