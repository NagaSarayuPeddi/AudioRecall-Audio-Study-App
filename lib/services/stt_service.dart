import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() async {
    return await _speech.initialize(
      onStatus: (status) => print("STT Status: $status"),
      onError: (error) => print("STT Error: $error"),
    );
  }

  Future<void> listen({required Function(String) onResult}) async {
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }
  // Future<void> listen({required Function(String) onResult}) async {
  //   await _speech.listen(
  //     // ignore: deprecated_member_use
  //     listenMode: ListenMode.confirmation,
  //     onResult: (result) {
  //       if (result.finalResult) {
  //         onResult(result.recognizedWords);
  //       }
  //     },
  //   );
  // }

  // Future<void> startListening(Function(String) onResult) {
  //   _speech.listen(
  //     onResult: (result) {
  //       onResult(result.recognizedWords);
  //     },
  //   );
  // }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
