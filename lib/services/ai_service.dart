import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:study_app/study_set.dart';
import 'package:study_app/flash_card.dart';

class AIService {
  static const String apiKey = "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";

  static Future<StudySet> generateStudySet(String topic, String number) async {
    final response = await http.post(
      Uri.parse(
        "https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta",
      ),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "inputs":
            "Generate a CSV with $number flashcards for the topic: $topic. Each line should have the format: word,definition",
      }),
    );

    if (response.statusCode != 200) {
      print("API Error: ${response.body}");
      return StudySet(id: "", name: topic, flashCards: [], description: "");
    }

    final data = jsonDecode(response.body);
    String text = data['choices'][0]['generated_text'];
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

    return StudySet(
      id: "",
      name: topic,
      description: "AI Generated $topic vocabulary",
      flashCards: flashCards,
    );
  }
}
