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
    return await _flutterTts.getVoices;
  }
}

class TTSSettings {
  static double speechRate = 0.5;
  static Map<String, String>? selectedVoice;
  static List<Map<String, String>> voices = [];

  static TTSService tts = TTSService();

  static Future<void> loadVoices() async {
    voices = List<Map<String, String>>.from(await tts.getVoices());
  }
}
