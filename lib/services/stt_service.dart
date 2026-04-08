import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class STTService {
  final SpeechToText _speech = SpeechToText();
  Completer<String>? answerCompleter;

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

  Future<String> listenOnce() async {
    String resultText = "";
    String lastWords = "";

    answerCompleter = Completer<String>();

    Timer? silenceTimer;

    await _speech.listen(
      onResult: (result) {
        lastWords = result.recognizedWords;
        silenceTimer?.cancel();
        silenceTimer = Timer(const Duration(seconds: 1), () {
          if (!answerCompleter!.isCompleted) {
            answerCompleter!.complete(lastWords);
          }
        });
      },
    );

    //await Future.delayed(Duration(seconds: 2));
    try {
      resultText = await answerCompleter!.future.timeout(
        Duration(seconds: 6),
      ); // max wait time
    } catch (e) {
      resultText = lastWords;
    }
    //esultText = await answerCompleter!.future.timeout(Duration(seconds: 10));
    print("Recognized speech: $resultText");
    await _speech.stop();

    //await Future.delayed(Duration(milliseconds: 500));

    return resultText.toLowerCase().trim();
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
