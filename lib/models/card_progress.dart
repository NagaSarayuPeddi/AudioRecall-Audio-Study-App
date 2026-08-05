/// Tracks a student's history with a single flash card.
class CardProgress {
  /// Matches FlashCard.id
  final String cardId;

  /// Matches StudySet.id
  final String setId;

  final String question;
  final String answer;

  int correctCount;
  int wrongCount;
  DateTime? lastStudied;

  CardProgress({
    required this.cardId,
    required this.setId,
    required this.question,
    required this.answer,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lastStudied,
  });

  // ─── Derived stats ───────────────────────────────────────────────────────

  int get totalAttempts => correctCount + wrongCount;

  /// 0.0 – 1.0
  double get accuracy =>
      totalAttempts == 0 ? 0.0 : correctCount / totalAttempts;

  /// Mastery label shown to the student
  String get masteryLabel {
    if (totalAttempts == 0) return 'Not studied';
    if (accuracy >= 0.9 && correctCount >= 3) return 'Mastered';
    if (accuracy >= 0.7) return 'Familiar';
    if (accuracy >= 0.4) return 'Learning';
    return 'Needs work';
  }

  /// Emoji for quick visual scanning
  String get masteryEmoji {
    switch (masteryLabel) {
      case 'Mastered':
        return '⭐';
      case 'Familiar':
        return '✅';
      case 'Learning':
        return '📖';
      case 'Needs work':
        return '🔁';
      default:
        return '⬜';
    }
  }

  /// Whether this card should be prioritised in a weak-cards drill
  bool get needsPractice => totalAttempts > 0 && accuracy < 0.7;

  // ─── Serialisation ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'cardId': cardId,
    'setId': setId,
    'question': question,
    'answer': answer,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'lastStudied': lastStudied?.toIso8601String(),
  };

  factory CardProgress.fromMap(Map<String, dynamic> map) => CardProgress(
    cardId: map['cardId'] as String,
    setId: map['setId'] as String,
    question: map['question'] as String? ?? '',
    answer: map['answer'] as String? ?? '',
    correctCount: map['correctCount'] as int? ?? 0,
    wrongCount: map['wrongCount'] as int? ?? 0,
    lastStudied: map['lastStudied'] != null
        ? DateTime.tryParse(map['lastStudied'] as String)
        : null,
  );
}
