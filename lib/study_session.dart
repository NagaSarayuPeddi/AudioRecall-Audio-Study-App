//import 'cards_page.dart';
import 'study_set.dart';
//import 'flash_card.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'package:flutter/material.dart';

class StudySession extends StatefulWidget {
  final StudySet setToStudy;

  const StudySession({super.key, required this.setToStudy});

  @override
  State<StudySession> createState() => _StudySessionState();
}

class _StudySessionState extends State<StudySession> {
  bool isSessionActive = false;
  int currentQuestionIndex = 0;

  final stt = STTService();
  final tts = TTSService();

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    tts.setSpeechRate(0.5);
    stt.initialize();
  }

  Future<void> startSession() async {
    setState(() {
      isSessionActive = true;
      currentQuestionIndex = 0;
    });
    await tts.speak(
      'Starting study session for set ${widget.setToStudy.name}.',
    );
    await readAnswer();
    await Future.delayed(const Duration(milliseconds: 500));
    startListening();
  }

  // void startListening() async {
  //   String spoken = '';
  //   if (!await stt.initialize()) {
  //     print("Speech recognition not available");
  //     return;
  //   }
  //   // if (!isListening) {
  //   setState(() => isListening = true);

  //   await stt.listen(
  //     onResult: (result) async {
  //       spoken = result.toLowerCase().trim();
  //       print("Spoken: $spoken");
  //       print(
  //         "Expected: ${widget.setToStudy.flashCards[currentQuestionIndex].question.toLowerCase().trim()}",
  //       );
  //     },
  //   );
  //   await stt.stopListening();

  //   // if (spoken.contains("done") || spoken.contains("ready")) {
  //   //   readAnswer();
  //   // }
  //   if (spoken.contains("stop")) {
  //     endSession();
  //     await tts.speak('Study session ended. Great job!');
  //     return;
  //   } else if (spoken.contains(
  //     widget.setToStudy.flashCards[currentQuestionIndex].question
  //         .toLowerCase()
  //         .trim(),
  //   )) {
  //     //await stt.stopListening();
  //     // setState(() {
  //     //   isListening = false;
  //     // });
  //     await tts.speak('Correct!');
  //     Future.delayed(const Duration(seconds: 2), () async {
  //       if (currentQuestionIndex < widget.setToStudy.flashCards.length - 1) {
  //         setState(() {
  //           currentQuestionIndex++;
  //         });
  //         await readAnswer();
  //         startListening();
  //         // setState(() {
  //         //   isListening = true;
  //         // });
  //       } else {
  //         endSession();
  //         await tts.speak(
  //           'Congratulations! You have completed the study session.',
  //         );
  //       }
  //     });
  //   } else {
  //     //await stt.stopListening();
  //     // setState(() {
  //     //   isListening = false;
  //     // });
  //     await tts.speak('Try again!');
  //     startListening();
  //   }

  //   // if (spoken.contains("stop")) {
  //   //   endSession();
  //   //   await tts.speak('Study session ended. Great job!');
  //   // }
  //   //},
  //   // );
  //   // }
  // }

  void startListening() async {
    if (!await stt.initialize()) {
      print("Speech recognition not available");
      return;
    }

    setState(() => isListening = true);

    await stt.listen(
      onResult: (spokenText) async {
        String spoken = spokenText.toLowerCase().trim();
        String expected = widget
            .setToStudy
            .flashCards[currentQuestionIndex]
            .question
            .toLowerCase()
            .trim();

        print("Spoken: $spoken");
        print("Expected: $expected");

        // Stop listening once we got a result
        await stt.stopListening();
        setState(() => isListening = false);

        // Check for stop command
        if (spoken.contains("stop")) {
          await tts.speak("Study session ended. Great job!");
          endSession();
          return;
        }

        // Check if user said the correct word
        if (spoken.contains(expected)) {
          await tts.speak("Correct!");
          await Future.delayed(Duration(milliseconds: 500));

          if (currentQuestionIndex < widget.setToStudy.flashCards.length - 1) {
            setState(() => currentQuestionIndex++);
            await readAnswer();
            await Future.delayed(Duration(milliseconds: 500));
            startListening(); // listen for next word
          } else {
            await tts.speak(
              "Congratulations! You have completed the study session.",
            );
            endSession();
          }
        } else {
          await tts.speak("Try again!");
          await Future.delayed(Duration(milliseconds: 500));
          startListening(); // try again
        }
      },
    );
  }

  Future<void> endSession() async {
    await stt.stopListening();
    setState(() {
      isSessionActive = false;
      isListening = false;
    });
  }

  Future<void> readQuestion() async {
    String question =
        widget.setToStudy.flashCards[currentQuestionIndex].question;
    await tts.speak(question);
  }

  Future<void> readAnswer() async {
    String answer = widget.setToStudy.flashCards[currentQuestionIndex].answer;
    await tts.speak(answer);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(isSessionActive ? 'End Session' : 'Start Session'),
      onPressed: () {
        if (isSessionActive) {
          endSession();
          tts.speak('Study session ended. Great job!');
        } else {
          startSession();
        }
      },
    );
  }
}
