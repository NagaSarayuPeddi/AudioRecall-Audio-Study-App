import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assisted_learning/models/card_progress.dart';
import 'package:assisted_learning/flash_card.dart';
import 'package:assisted_learning/study_set.dart';

/// Persists per-card study statistics across sessions.
///
/// Storage layout:
///   Key: 'progress_{setId}_{cardId}'
///   Value: JSON encoded CardProgress map
class ProgressService {
  ProgressService._();

  static const String _prefix = 'progress_';

  // ─── Write ───────────────────────────────────────────────────────────────

  /// Record a correct answer for [card] in [set].
  static Future<void> recordCorrect(StudySet set, FlashCard card) async {
    final progress =
        await _load(set.id, card.id) ??
        CardProgress(
          cardId: card.id,
          setId: set.id,
          question: card.question,
          answer: card.answer,
        );
    progress.correctCount++;
    progress.lastStudied = DateTime.now();
    await _save(progress);
  }

  /// Record a wrong answer for [card] in [set].
  static Future<void> recordWrong(StudySet set, FlashCard card) async {
    final progress =
        await _load(set.id, card.id) ??
        CardProgress(
          cardId: card.id,
          setId: set.id,
          question: card.question,
          answer: card.answer,
        );
    progress.wrongCount++;
    progress.lastStudied = DateTime.now();
    await _save(progress);
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  /// Load progress for a single card. Returns null if never studied.
  static Future<CardProgress?> loadCard(String setId, String cardId) async {
    return _load(setId, cardId);
  }

  /// Load progress for every card in [set].
  /// Cards never studied are included with zero counts.
  static Future<List<CardProgress>> loadSet(StudySet set) async {
    final prefs = await SharedPreferences.getInstance();
    final results = <CardProgress>[];

    for (final card in set.flashCards) {
      final key = _key(set.id, card.id);
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          results.add(
            CardProgress.fromMap(jsonDecode(raw) as Map<String, dynamic>),
          );
        } catch (_) {
          results.add(
            CardProgress(
              cardId: card.id,
              setId: set.id,
              question: card.question,
              answer: card.answer,
            ),
          );
        }
      } else {
        results.add(
          CardProgress(
            cardId: card.id,
            setId: set.id,
            question: card.question,
            answer: card.answer,
          ),
        );
      }
    }
    return results;
  }

  /// Returns only cards that need practice (accuracy < 70%).
  static Future<List<CardProgress>> weakCards(StudySet set) async {
    final all = await loadSet(set);
    return all.where((p) => p.needsPractice).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
  }

  /// Overall mastery percentage for a set (0–100).
  static Future<int> setMasteryPercent(StudySet set) async {
    final all = await loadSet(set);
    if (all.isEmpty) return 0;
    final mastered = all.where((p) => p.masteryLabel == 'Mastered').length;
    return ((mastered / all.length) * 100).round();
  }

  /// Delete all progress for a set (e.g. when the set is deleted).
  static Future<void> clearSet(String setId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith('${_prefix}${setId}_'),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  static String _key(String setId, String cardId) =>
      '${_prefix}${setId}_$cardId';

  static Future<CardProgress?> _load(String setId, String cardId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(setId, cardId));
      if (raw == null) return null;
      return CardProgress.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      print('ProgressService._load error: $e');
      return null;
    }
  }

  static Future<void> _save(CardProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(progress.setId, progress.cardId),
        jsonEncode(progress.toMap()),
      );
    } catch (e) {
      print('ProgressService._save error: $e');
    }
  }
}
