//import 'cards_page.dart';
import 'study_set.dart';
//import 'flash_card.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class StudySessionScreen extends StatefulWidget {
  final StudySet setToStudy;

  const StudySessionScreen({super.key, required this.setToStudy});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  bool isSessionActive = false;
  //bool isRetrying = false;
  int currentQuestionIndex = 0;
  int num = 1;
  Color bgdColor = Colors.white;
  bool tap = false;
  bool doubleTap = false;

  final stt = STTService();
  final tts = TTSService();

  Completer<String>? tapCompleter;
  Completer<String>? answerCompleter;

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    tts.setSpeechRate(1);
    stt.initialize();
  }

  Future<void> startSession() async {
    setState(() {
      isSessionActive = true;
      currentQuestionIndex = 0;
      bgdColor = Colors.blue;
    });
    await tts.speak(
      'Starting study session for set ${widget.setToStudy.name}.',
    );

    runQuestion(false);
    // await readAnswer();
    // await Future.delayed(const Duration(milliseconds: 500));
    //startListening();

    // while (isSessionActive) {
    //   if (currentQuestionIndex >= widget.setToStudy.flashCards.length) {
    //     await tts.speak(
    //       "Congratulations! You have completed the study session.",
    //     );

    //     endSession();
    //     return;
    //   }

    //   await readAnswer();
    //   setState(() {
    //     bgdColor = Colors.blue;
    //   });
    //   await Future.delayed(const Duration(seconds: 1));

    //   String userAnswer = await listenOnce();
    //   setState(() {
    //     bgdColor = Colors.black;
    //   });
    //   String expectedAnswer = widget
    //       .setToStudy
    //       .flashCards[currentQuestionIndex]
    //       .question
    //       .toLowerCase()
    //       .trim();
    //   if (userAnswer.contains("stop")) {
    //     await tts.speak("Study session ended. Great job!");

    //     endSession();
    //     return;
    //   }
    //   if (userAnswer.contains(expectedAnswer)) {
    //     setState(() {
    //       bgdColor = Colors.green;
    //     });
    //     await tts.speak("Correct!");
    //     await Future.delayed(const Duration(milliseconds: 500));
    //     currentQuestionIndex++;
    //   } else if (userAnswer == "" || userAnswer.contains("i don't know")) {
    //     setState(() {
    //       bgdColor = Colors.black;
    //     });
    //     await tts.speak(
    //       "Tap the screen to hear the correct answer or double tap to keep trying.",
    //     );
    //     setState(() {
    //       bgdColor = Colors.blue;
    //     });
    //     await Future.delayed(const Duration(seconds: 5));
    //     if (tap) {
    //       await readQuestion();
    //       tap = false;
    //       currentQuestionIndex++;
    //     } else if (doubleTap) {
    //       doubleTap = false;
    //     } else {
    //       await tts.speak("Let's try that one again.");
    //       await Future.delayed(const Duration(milliseconds: 500));
    //     }

    //     await Future.delayed(const Duration(milliseconds: 500));
    //   } else {
    //     setState(() {
    //       bgdColor = Colors.red;
    //     });
    //     await tts.speak("Try again!");
    //     await Future.delayed(const Duration(milliseconds: 500));
    //     //userAnswer = await listenOnce();
    //   }
    // }
  }

  Future<String> listenOnce() async {
    String resultText = "";
    String lastWords = "";

    answerCompleter = Completer<String>();

    Timer? silenceTimer;

    await stt.listen(
      onResult: (spokenText) {
        lastWords = spokenText;
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
        Duration(seconds: 5),
      ); // max wait time
    } catch (e) {
      resultText = lastWords;
    }
    //esultText = await answerCompleter!.future.timeout(Duration(seconds: 10));
    print("Recognized speech: $resultText");
    await stt.stopListening();

    //await Future.delayed(Duration(milliseconds: 500));

    return resultText.toLowerCase().trim();
  }

  Future<void> runQuestion(bool isRetrying) async {
    if (!isSessionActive) return;

    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) {
      await tts.speak("Congratulations! You finished!");
      endSession();
      return;
    }

    if (!isRetrying) {
      await readAnswer(num);
    }

    setState(() {
      bgdColor = Colors.blue;
    });

    String userAnswer = await listenOnce();

    await handleAnswer(userAnswer);
  }

  Future<void> handleAnswer(String userAnswer) async {
    String expectedAnswer = widget
        .setToStudy
        .flashCards[currentQuestionIndex]
        .question
        .toLowerCase()
        .trim();

    // stop
    if (userAnswer.contains("stop")) {
      await tts.speak("Study session ended. Great job!");
      endSession();
      return;
    }

    // answer is correct
    if (userAnswer == expectedAnswer) {
      setState(() {
        bgdColor = Colors.green;
      });
      await tts.speak("Correct!");

      currentQuestionIndex++;
      num++;
      await Future.delayed(const Duration(milliseconds: 500));

      runQuestion(false);
    }
    // no answer is given or they don't know (retry logic also in this)
    else if (userAnswer == "" || userAnswer.contains("don't know")) {
      setState(() {
        bgdColor = Colors.black;
      });

      await tts.speak(
        "Tap the screen to hear the correct answer, or double tap to keep trying.",
      );

      tapCompleter = Completer<String>();

      String action = await tapCompleter!.future;

      if (action == "tap") {
        await readQuestion();
        currentQuestionIndex++;
        num++;
        //await Future.delayed(const Duration(milliseconds: 500));
        runQuestion(false);
      } else if (action == "double") {
        //await Future.delayed(const Duration(milliseconds: 500));
        runQuestion(true); // this will retry without repeating the definition
      } else if (action == "cancel") {
        return;
      }
    }
    // answer is wrong
    else {
      setState(() {
        bgdColor = Colors.red;
      });

      await tts.speak("Try again!");
      //await Future.delayed(const Duration(milliseconds: 500));
      runQuestion(true); // retry the same question
    }
  }

  // void startListening() async {
  //   if (!await stt.initialize()) {
  //     print("Speech recognition not available");
  //     return;
  //   }

  //   setState(() => isListening = true);

  //   await stt.listen(
  //     onResult: (spokenText) async {
  //       String spoken = spokenText.toLowerCase().trim();
  //       String expected = widget
  //           .setToStudy
  //           .flashCards[currentQuestionIndex]
  //           .question
  //           .toLowerCase()
  //           .trim();

  //       print("Spoken: $spoken");
  //       print("Expected: $expected");

  //       // Stop listening once we got a result
  //       await stt.stopListening();
  //       setState(() => isListening = false);

  //       // Check for stop command
  //       if (spoken.contains("stop")) {
  //         await tts.speak("Study session ended. Great job!");
  //         endSession();
  //         return;
  //       }

  //       // Check if user said the correct word
  //       if (spoken.contains(expected)) {
  //         await tts.speak("Correct!");
  //         await Future.delayed(Duration(milliseconds: 500));

  //         if (currentQuestionIndex < widget.setToStudy.flashCards.length - 1) {
  //           setState(() => currentQuestionIndex++);
  //           await Future.delayed(Duration(milliseconds: 300));

  //           await readAnswer(); // speak next definition
  //           await Future.delayed(Duration(milliseconds: 700));

  //           startListening(); // listen for next word
  //         } else {
  //           await tts.speak(
  //             "Congratulations! You have completed the study session.",
  //           );
  //           endSession();
  //         }
  //       } else {
  //         await tts.speak("Try again!");
  //         await Future.delayed(Duration(milliseconds: 500));
  //         startListening(); // try again
  //       }
  //     },
  //   );
  // }

  Future<void> endSession() async {
    tts.stop();
    await stt.stopListening();
    if (tapCompleter != null && !tapCompleter!.isCompleted) {
      tapCompleter!.complete("cancel");
    }
    setState(() {
      isSessionActive = false;
      isListening = false;
      bgdColor = Colors.white;
    });
  }

  Future<void> readQuestion() async {
    String question =
        widget.setToStudy.flashCards[currentQuestionIndex].question;
    await tts.speak("The correct answer is: $question");
  }

  Future<void> readAnswer(int number) async {
    String answer = widget.setToStudy.flashCards[currentQuestionIndex].answer;
    setState(() {
      bgdColor = Colors.black;
    });
    await tts.speak("Number $number : $answer");
    setState(() {
      bgdColor = Colors.white;
    });
  }

  @override
  // Widget build(BuildContext context) {
  //   return TextButton(
  //     child: Text(isSessionActive ? 'End Session' : 'Start Session'),
  //     onPressed: () {
  //       if (isSessionActive) {
  //         endSession();
  //         tts.speak('Study session ended. Great job!');
  //       } else {
  //         startSession();
  //       }
  //     },
  //   );
  // }
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tapCompleter != null && !tapCompleter!.isCompleted) {
          tapCompleter!.complete("tap");
        }
        setState(() {
          tap = true;
          doubleTap = false;
        });
      },
      onDoubleTap: () {
        if (tapCompleter != null && !tapCompleter!.isCompleted) {
          tapCompleter!.complete("double");
        }
        setState(() {
          doubleTap = true;
          tap = false;
        });
      },
      child: Scaffold(
        backgroundColor: bgdColor,
        appBar: AppBar(title: Text("Study Session"), centerTitle: true),
        body: Center(
          child: ElevatedButton(
            child: Text(isSessionActive ? 'End Session' : 'Start Session'),
            onPressed: () {
              if (isSessionActive) {
                endSession();
                tts.speak('Study session ended. Great job!');
              } else {
                startSession();
              }
            },
          ),
        ),
      ),
    );
  }
}
