import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_app/study_set.dart';
import 'package:study_app/flash_card.dart';

/// Handles saving and loading all user-created study sets.
///
/// Sets are stored as a JSON array under the key [_setsKey].
/// Each StudySet is serialised to/from a Map so no external
/// serialisation package is required.
class PersistenceService {
  PersistenceService._();
  static const String _setsKey = 'echolearn_study_sets';

  // ─── Public API ────────────────────────────────────────────

  /// Load all saved sets. Returns an empty list when nothing is stored yet.
  static Future<List<StudySet>> loadSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_setsKey);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => _setFromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Corrupt data — start fresh rather than crash
      print('PersistenceService.loadSets error: $e');
      return [];
    }
  }

  /// Persist the full list of sets, overwriting whatever was there before.
  static Future<void> saveSets(List<StudySet> sets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(sets.map(_setToMap).toList());
      await prefs.setString(_setsKey, encoded);
    } catch (e) {
      print('PersistenceService.saveSets error: $e');
    }
  }

  /// Add a single set and save.
  static Future<void> addSet(
    List<StudySet> currentSets,
    StudySet newSet,
  ) async {
    currentSets.add(newSet);
    await saveSets(currentSets);
  }

  /// Remove a set by id and save.
  static Future<void> removeSet(
    List<StudySet> currentSets,
    StudySet setToRemove,
  ) async {
    currentSets.removeWhere((s) => s.id == setToRemove.id);
    await saveSets(currentSets);
  }

  /// Call this after editing any set's cards or name to persist the change.
  static Future<void> updateSet(
    List<StudySet> currentSets,
    StudySet updatedSet,
  ) async {
    final index = currentSets.indexWhere((s) => s.id == updatedSet.id);
    if (index != -1) {
      currentSets[index] = updatedSet;
      await saveSets(currentSets);
    }
  }

  // ─── Serialisation helpers ─────────────────────────────────

  static Map<String, dynamic> _setToMap(StudySet set) {
    return {
      'id': set.id,
      'name': set.name,
      'description': set.description,
      'isEditing': set.isEditing,
      'flashCards': set.flashCards.map(_cardToMap).toList(),
    };
  }

  static StudySet _setFromMap(Map<String, dynamic> map) {
    return StudySet(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isEditing: map['isEditing'] as bool? ?? false,
      flashCards: (map['flashCards'] as List<dynamic>? ?? [])
          .map((c) => _cardFromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _cardToMap(FlashCard card) {
    return {
      'id': card.id,
      'question': card.question,
      'answer': card.answer,
      'isEditing': card.isEditing,
    };
  }

  static FlashCard _cardFromMap(Map<String, dynamic> map) {
    return FlashCard(
      id: map['id'] as String? ?? '',
      question: map['question'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      isEditing: map['isEditing'] as bool? ?? false,
    );
  }
}
