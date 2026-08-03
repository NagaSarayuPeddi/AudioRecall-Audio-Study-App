/// Fuzzy answer matcher for EchoLearn study sessions.
class MatchResult {
  /// Whether the answer should be counted as correct
  final bool isCorrect;

  /// 0.0 – 1.0 confidence that this is a match
  final double score;

  /// Human-readable reason, useful for debugging
  final String reason;

  const MatchResult({
    required this.isCorrect,
    required this.score,
    required this.reason,
  });

  @override
  String toString() =>
      'MatchResult(correct: $isCorrect, score: ${score.toStringAsFixed(2)}, reason: $reason)';
}

class AnswerMatcher {
  AnswerMatcher._();

  // Words that should be stripped before comparing
  static const _fillerWords = {
    'the',
    'a',
    'an',
    'uh',
    'um',
    'er',
    'like',
    'so',
    'well',
    'it',
    'is',
    'its',
    "it's",
    'that',
    'this',
  };

  // Score thresholds
  static const double _exactThreshold = 1.0;
  static const double _closeThreshold = 0.75; // counts as correct
  static const double _hintThreshold = 0.50; // "you're close" feedback

  /// Main entry point. Pass in the raw STT text and the expected answer.
  static MatchResult match(String spoken, String expected) {
    final cleanSpoken = _normalise(spoken);
    final cleanExpected = _normalise(expected);

    if (cleanSpoken.isEmpty) {
      return const MatchResult(
        isCorrect: false,
        score: 0,
        reason: 'No speech detected',
      );
    }

    // 1. Exact match after normalisation
    if (cleanSpoken == cleanExpected) {
      return const MatchResult(
        isCorrect: true,
        score: 1.0,
        reason: 'Exact match',
      );
    }

    // 2. Spoken contains the expected answer as a substring
    //    e.g. "it is scarcity" contains "scarcity"
    if (cleanSpoken.contains(cleanExpected)) {
      return const MatchResult(
        isCorrect: true,
        score: 0.95,
        reason: 'Expected answer found within spoken text',
      );
    }

    // 3. Word-level match — all key words of the expected answer are present
    final spokenWords = cleanSpoken.split(' ').toSet();
    final expectedWords = cleanExpected.split(' ').toSet();
    final keyWords = expectedWords.difference(_fillerWords).toSet();

    if (keyWords.isNotEmpty && spokenWords.containsAll(keyWords)) {
      return const MatchResult(
        isCorrect: true,
        score: 0.90,
        reason: 'All key words matched',
      );
    }

    // 4. Stem match — compare word stems for basic plural/verb handling
    final spokenStems = spokenWords.map(_stem).toSet();
    final expectedStems = expectedWords.map(_stem).toSet();
    final keyStems = expectedStems.difference(_fillerWords.map(_stem).toSet());

    if (keyStems.isNotEmpty && spokenStems.containsAll(keyStems)) {
      return const MatchResult(
        isCorrect: true,
        score: 0.85,
        reason: 'Stem match (e.g. plural or verb form accepted)',
      );
    }

    // 5. Edit-distance (Levenshtein) on the full normalised strings
    //    Catches mishearing like "inflasion" vs "inflation"
    final distance = _levenshtein(cleanSpoken, cleanExpected);
    final maxLen = cleanSpoken.length > cleanExpected.length
        ? cleanSpoken.length
        : cleanExpected.length;

    final similarity = maxLen == 0 ? 1.0 : 1.0 - (distance / maxLen);

    if (similarity >= _closeThreshold) {
      return MatchResult(
        isCorrect: true,
        score: similarity,
        reason:
            'Close enough (edit distance $distance, similarity '
            '${(similarity * 100).round()}%)',
      );
    }

    if (similarity >= _hintThreshold) {
      return MatchResult(
        isCorrect: false,
        score: similarity,
        reason: 'Close but not quite (${(similarity * 100).round()}%)',
      );
    }

    return MatchResult(
      isCorrect: false,
      score: similarity,
      reason: 'No match (${(similarity * 100).round()}% similar)',
    );
  }

  /// Returns true if the answer is "close but wrong" — useful for giving
  /// a "you're almost there" hint instead of a flat "wrong".
  static bool isAlmostCorrect(MatchResult result) =>
      !result.isCorrect && result.score >= _hintThreshold;

  // ─── Private helpers ────────────────────────────────────────────────────

  /// Lowercase, strip punctuation, remove filler words, collapse spaces.
  static String _normalise(String input) {
    var s = input.toLowerCase();

    // Remove punctuation
    s = s.replaceAll(RegExp(r"[^\w\s']"), '');

    // Collapse contractions (don't → dont) so they don't trip the matcher
    s = s.replaceAll("'", '');

    // Remove filler words
    final words = s
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_fillerWords.contains(w))
        .toList();

    return words.join(' ').trim();
  }

  /// Very basic English stemmer: strips common suffixes.
  /// Not perfect, but handles the most common STT variations.
  static String _stem(String word) {
    if (word.length <= 3) return word;

    // Order matters — check longer suffixes first
    const suffixes = [
      'tion',
      'sion',
      'ness',
      'ment',
      'ity',
      'ing',
      'ion',
      'ies',
      'ied',
      'ers',
      'est',
      'ed',
      'es',
      'er',
      'ly',
      's',
    ];

    for (final suffix in suffixes) {
      if (word.endsWith(suffix) && word.length > suffix.length + 2) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  /// Standard Levenshtein edit distance.
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Use two rows to save memory
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1, // insertion
          prev[j] + 1, // deletion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      // Swap rows
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }
}
