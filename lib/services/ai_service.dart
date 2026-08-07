import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:AudioRecall/sets_screen.dart';
import 'package:AudioRecall/flash_card.dart';
import 'app_config.dart';

class AIService {
  // No API key here — loaded securely from .env via AppConfig

  static Future<StudySet?> generateStudySet(String topic, String number) async {
    final String apiKey;

    try {
      apiKey = AppConfig.cohereApiKey;
    } catch (e) {
      print('Config error: $e');
      return null;
    }

    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('https://api.cohere.ai/v1/chat'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'command-a-03-2025',
              'message':
                  'Generate a CSV with $number flashcards for the topic: $topic. '
                  'No extra text before or after. '
                  'The CSV should have the title in the first row and all '
                  'preceding rows should have the format: word,definition. '
                  'Do not put quotes around the words or definitions.',
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Request timed out after 60s'),
          );
    } on Exception catch (e) {
      print('Network error generating study set: $e');
      return null;
    }

    if (response.statusCode != 200) {
      print('API Error ${response.statusCode}: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body);
    final String text = data['text'] as String? ?? '';

    if (text.trim().isEmpty) {
      print('Empty response from API');
      return null;
    }

    return _convertCSVToStudySet(text, topic);
  }

  static StudySet _convertCSVToStudySet(String csvText, String topic) {
    final List<FlashCard> flashCards = [];

    // Strip code fences if the model wrapped its output
    final cleaned = csvText
        .replaceAll('```csv', '')
        .replaceAll('```', '')
        .trim();

    final lines = cleaned.split('\n');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Split on first comma only so definitions with commas survive
      final commaIndex = line.indexOf(',');
      if (commaIndex == -1) continue;

      final word = line.substring(0, commaIndex).trim();
      final definition = line.substring(commaIndex + 1).trim();

      if (word.isEmpty || definition.isEmpty) continue;

      flashCards.add(
        FlashCard(
          id: i.toString(),
          question: word,
          answer: definition,
          isEditing: false,
        ),
      );
    }

    // Title-case the topic name
    final formattedTopic = topic
        .split(' ')
        .map(
          (w) =>
              w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');

    return StudySet(
      id: '',
      name: formattedTopic,
      description: 'AI generated — $formattedTopic',
      flashCards: flashCards,
      isEditing: false,
    );
  }
}
