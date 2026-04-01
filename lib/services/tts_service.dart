import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  Future<List<dynamic>> getVoices() async {
    List<dynamic> voices = await _flutterTts.getVoices;

    if (voices.isEmpty) {
      await Future.delayed(Duration(milliseconds: 500));
      voices = await _flutterTts.getVoices;
    }

    return voices;
  }
}

class TTSSettings {
  static double speechRate = 0.5;
  static Map<String, String>? selectedVoice;
  static List<Map<String, String>> voices = [];

  static TTSService tts = TTSService();

  static Future<void> loadVoices() async {
    final List<dynamic> rawVoices = await tts.getVoices();

    if (rawVoices.isEmpty) {
      await Future.delayed(Duration(seconds: 1));
    }

    voices = rawVoices.map<Map<String, String>>((voice) {
      final v = Map<String, String>.from(voice);
      return {
        'name': v['name']?.toString() ?? 'Unknown',
        'locale': v['locale']?.toString() ?? 'Unknown',
      };
    }).toList();

    print("Loaded voices: ${voices.length}");
    print(voices);
  }
}
