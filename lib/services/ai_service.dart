import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:study_app/study_set.dart';
import 'package:study_app/flash_card.dart';

class AIService {
  static const String apiKey = "cERpXicxTBqyEpcAtJRUlyDvXS6fW6KRJZAQozzY";

  static Future<StudySet> generateStudySet(String topic, String number) async {
    final response = await http.post(
      Uri.parse("https://api.cohere.ai/v1/chat"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "command-a-03-2025",
        "message":
            "Generate a CSV with $number flashcards for the topic: $topic. No Extra text before of after. The CSV should have the title in the first row and all preceeding rows should have the format: word,definition. Do not put "
            " around the words or definitions.",
      }),
    );

    if (response.statusCode != 200) {
      print("API Error: ${response.body}");
      return StudySet(id: "", name: topic, flashCards: [], description: "");
    }

    final data = jsonDecode(response.body);
    String text = data['text'];
    print("Raw API response:\n$text");

    return convertCSVToStudySet(text, topic);
  }

  static StudySet convertCSVToStudySet(String csvText, String topic) {
    List<FlashCard> flashCards = [];
    csvText = csvText.replaceAll("```", "").trim();
    List<String> lines = csvText.split("\n");

    for (int i = 1; i < lines.length; i++) {
      List<String> parts = lines[i].split(',');

      if (parts.length < 2) continue;

      flashCards.add(
        FlashCard(
          id: i.toString(),
          question: parts[0].trim(),
          answer: parts.sublist(1).join(',').trim(),
          isEditing: false,
        ),
      );
    }

    topic = topic
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    return StudySet(
      id: "",
      name: topic,
      description: "AI Generated $topic vocabulary",
      flashCards: flashCards,
    );
  }
}
