import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  void startListening(Function(String) onResult) {
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  void stopListening() {
    _speech.stop();
  }
}
