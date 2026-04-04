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
  bool showAnswer = false;

  int correctAnswers = 0;
  int wrongAnswers = 0;
  int attempts = 0;

  // double speechRate = 1.0;
  // List<dynamic> voices = [];
  // Map<String, String>? selectedVoice;

  final stt = STTService();
  //final tts = TTSService();

  Completer<String>? tapCompleter;
  Completer<String>? answerCompleter;

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    //loadVoices();
    TTSSettings.tts.setSpeechRate(TTSSettings.speechRate);
    stt.initialize();
  }

  // Future<void> loadVoices() async {
  //   TTSSettings.voices = await TTSSettings.tts.getVoices();

  //   if (TTSSettings.voices.isNotEmpty) {
  //     TTSSettings.selectedVoice = TTSSettings.voices.first;
  //     await TTSSettings.tts.setVoice(TTSSettings.selectedVoice!);
  //   }

  //   setState(() {});
  // }

  Future<void> startSession() async {
    setState(() {
      isSessionActive = true;
      currentQuestionIndex = 0;
      num = 1;
      wrongAnswers = 0;
      correctAnswers = 0;
      attempts = 0;
      bgdColor = Colors.blue;
    });
    await TTSSettings.tts.speak(
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
      await TTSSettings.tts.speak("Congratulations! You finished!");
      await speakSummary();
      endSession();
      return;
    }

    if (!isRetrying) {
      await readAnswer(num);
    } else {
      attempts++;
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
      await TTSSettings.tts.speak("Study session ended. Great job!");
      endSession();
      return;
    }

    // answer is correct
    if (userAnswer == expectedAnswer) {
      setState(() {
        bgdColor = Colors.green;
        if (attempts == 1) {
          correctAnswers++;
        }
      });
      await TTSSettings.tts.speak("Correct!");

      setState(() {
        currentQuestionIndex++;
        showAnswer = false;
      });
      num++;
      await Future.delayed(const Duration(milliseconds: 500));

      runQuestion(false);
    }
    // no answer is given or they don't know (retry logic also in this)
    else if (userAnswer == "" || userAnswer.contains("don't know")) {
      setState(() {
        bgdColor = Colors.black;
      });
      if (userAnswer.contains("don't know")) {
        await TTSSettings.tts.speak(
          "No worries, do you want to hear the correct answer?",
        );

        await stt.listen(
          onResult: (spokenText) async {
            String response = spokenText.toLowerCase();
            if (response.contains("yes") || response.contains("sure")) {
              if (!tapCompleter!.isCompleted) {
                tapCompleter!.complete("tap");
              }
              wrongAnswers++;
            } else if (response.contains("no") ||
                response.contains("not now")) {
              if (!tapCompleter!.isCompleted) {
                tapCompleter!.complete("double");
              }
            }
          },
        );
      } else {
        await TTSSettings.tts.speak(
          "Do you need help? Tap the screen to hear the correct answer, or double tap to keep trying.",
        );
      }

      tapCompleter = Completer<String>();

      String action = await tapCompleter!.future;

      if (action == "tap") {
        await readQuestion();
        setState(() {
          currentQuestionIndex++;
          showAnswer = false;
        });
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
        wrongAnswers++;
      });

      await TTSSettings.tts.speak("Try again!");
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
    TTSSettings.tts.stop();
    await stt.stopListening();
    if (tapCompleter != null && !tapCompleter!.isCompleted) {
      tapCompleter!.complete("cancel");
    }

    showSummaryDialog();
    speakSummary();

    setState(() {
      isSessionActive = false;
      isListening = false;
      bgdColor = Colors.white;
    });
  }

  Future<void> readQuestion() async {
    String question =
        widget.setToStudy.flashCards[currentQuestionIndex].question;
    await TTSSettings.tts.speak("The correct answer is: $question");
    attempts = 1;
  }

  Future<void> readAnswer(int number) async {
    String answer = widget.setToStudy.flashCards[currentQuestionIndex].answer;
    setState(() {
      bgdColor = Colors.black;
    });
    await TTSSettings.tts.speak("Number $number : $answer");
    setState(() {
      bgdColor = Colors.white;
    });
  }

  Future<void> speakSummary() async {
    await TTSSettings.tts.speak("Do you want to hear your session summary?");
    Future.delayed(const Duration(seconds: 1));
    await stt.listen(
      onResult: (spokenText) async {
        String response = spokenText.toLowerCase();
        if (response.contains("yes") || response.contains("sure")) {
          if (!tapCompleter!.isCompleted) {
            await TTSSettings.tts.speak(
              "You got $correctAnswers correct and $wrongAnswers wrong out of ${widget.setToStudy.flashCards.length} questions.",
            );
          }
        } else {
          await TTSSettings.tts.speak("Okay. Bye!");
        }
      },
    );
  }

  void showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Session Summary"),
          content: Text(
            "Correct: $correctAnswers\nWrong: $wrongAnswers\nTotal: ${widget.setToStudy.flashCards.length}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
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
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Studying: ${widget.setToStudy.name}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Tap the card to show the answer",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                setState(() {
                  showAnswer = !showAnswer;
                });
              },
              child: Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      showAnswer
                          ? Text(
                              widget
                                  .setToStudy
                                  .flashCards[currentQuestionIndex]
                                  .answer,
                              style: TextStyle(fontSize: 30),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              widget
                                  .setToStudy
                                  .flashCards[currentQuestionIndex]
                                  .question,
                              style: TextStyle(
                                fontSize: 65,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
              ),
            ),

            Text(
              "${currentQuestionIndex + 1} of ${widget.setToStudy.flashCards.length}",
              style: TextStyle(fontSize: 25),
            ),

            SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (currentQuestionIndex > 0) {
                        currentQuestionIndex--;
                        showAnswer = false;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_back_ios),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (currentQuestionIndex <
                          widget.setToStudy.flashCards.length - 1) {
                        currentQuestionIndex++;
                        showAnswer = false;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),

            SizedBox(height: 10),

            ElevatedButton(
              child: Text(isSessionActive ? 'End Session' : 'Start Session'),
              onPressed: () {
                if (isSessionActive) {
                  endSession();
                  TTSSettings.tts.speak('Study session ended. Great job!');
                } else {
                  startSession();
                }
              },
            ),
            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value:
                        (currentQuestionIndex + 1) /
                        widget.setToStudy.flashCards.length,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),

                  SizedBox(height: 8),

                  Text(
                    "${(((currentQuestionIndex + 1) / widget.setToStudy.flashCards.length) * 100).round()}% completed",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
