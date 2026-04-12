//import 'cards_page.dart';
import 'study_set.dart';
//import 'flash_card.dart';
import 'main.dart';
import 'profile_screen.dart';
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
  Color bgdColor = const Color(0xFF364B9A); //navy
  // bool tap = false;
  // bool doubleTap = false;
  bool showDefinition = false;

  int correctAnswers = 0;
  int wrongAnswers = 0;
  int attempts = 0;

  // double speechRate = 1.0;
  // List<dynamic> voices = [];
  // Map<String, String>? selectedVoice;

  //final stt = STTService();
  //final tts = TTSService();

  Completer<String>? tapCompleter;
  // Completer<String>? answerCompleter;

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    //loadVoices();
    TTSSettings.tts.setSpeechRate(TTSSettings.speechRate);
    STTService().initialize();
  }

  Future<void> startSession() async {
    setState(() {
      isSessionActive = true;
      currentQuestionIndex = 0;
      num = 1;
      wrongAnswers = 0;
      correctAnswers = 0;
      attempts = 1;
      bgdColor = Colors.blue;
      showDefinition = true;
    });
    await TTSSettings.tts.speak(
      'Starting study session for set ${widget.setToStudy.name}.',
    );

    await runQuestion(false);
  }

  Future<void> runQuestion(bool isRetrying) async {
    if (!isSessionActive) return;

    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) {
      await TTSSettings.tts.speak("Congratulations! You finished!");
      //await speakSummary();
      endSession();
      return;
    }

    setState(() {
      showDefinition = true;
    });

    if (!isRetrying) {
      attempts = 1;
      await readAnswer(num);
    } else {
      attempts++;
    }

    setState(() {
      bgdColor = Colors.blue;
    });

    String userAnswer = await STTService().listenOnce();

    if (!isSessionActive) return;

    await handleAnswer(userAnswer);
  }

  Future<void> handleAnswer(String userAnswer) async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) {
      return;
    }

    String expectedAnswer = widget
        .setToStudy
        .flashCards[currentQuestionIndex]
        .question
        .toLowerCase()
        .trim();

    //String secondResponse = "";

    // stop
    if (userAnswer.contains("stop")) {
      await TTSSettings.tts.speak("Study session ended. Great job!");
      endSession();
      return;
    }

    // answer is correct
    if (userAnswer.trim() == expectedAnswer) {
      setState(() {
        bgdColor = Colors.green;
        if (attempts == 1) {
          correctAnswers++;
          print("correct answers: $correctAnswers");
        }
      });
      await TTSSettings.tts.speak("Correct!");

      setState(() {
        currentQuestionIndex++;
        // showDefinition = false;
      });
      num++;
      await Future.delayed(const Duration(milliseconds: 500));
      if (currentQuestionIndex <= widget.setToStudy.flashCards.length) {
        await runQuestion(false);
      }
    }
    // no answer is given or they don't know
    else if (userAnswer == "" || userAnswer.contains("don't know")) {
      setState(() {
        bgdColor = Colors.black;
      });
      if (userAnswer.contains("don't know")) {
        await TTSSettings.tts.speak(
          "No worries, do you want to hear the correct answer?",
        );

        //await Future.delayed(const Duration(seconds: 5));
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          bgdColor = Colors.blue;
        });

        String yesOrNo = await STTService().listenOnce();
        print("Yes or No response: $yesOrNo");

        if (yesOrNo.contains("yes") || yesOrNo.contains("sure")) {
          await readQuestion();
          if (attempts == 1) {
            wrongAnswers++;
          }
          print("wrong answers: $wrongAnswers");

          setState(() {
            currentQuestionIndex++;
            // showDefinition = false;
          });
          num++;
          await Future.delayed(const Duration(milliseconds: 500));

          if (currentQuestionIndex <= widget.setToStudy.flashCards.length) {
            await runQuestion(false);
          }
        } else {
          await TTSSettings.tts.speak("Okay, let's try that one again.");
          await Future.delayed(const Duration(milliseconds: 500));
          await runQuestion(true);
        }
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
          showDefinition = false;
          if (attempts == 1) {
            wrongAnswers++;
          }
          print("wrong answers: $wrongAnswers");
        });
        num++;
        //await Future.delayed(const Duration(milliseconds: 500));
        if (currentQuestionIndex <= widget.setToStudy.flashCards.length) {
          await runQuestion(false);
        }
      } else if (action == "double") {
        //await Future.delayed(const Duration(milliseconds: 500));
        await runQuestion(
          true,
        ); // this will retry without repeating the definition
      } else if (action == "cancel") {
        return;
      }
    }
    // answer is wrong
    else {
      setState(() {
        bgdColor = Colors.red;
        if (attempts == 1) {
          wrongAnswers++;
        }
        print("wrong answers: $wrongAnswers");
      });

      await TTSSettings.tts.speak("Try again!");
      //await Future.delayed(const Duration(milliseconds: 500));
      await runQuestion(true); // retry the same question
    }
  }

  Future<void> endSession() async {
    TTSSettings.tts.stop();
    await STTService().stopListening();
    if (tapCompleter != null && !tapCompleter!.isCompleted) {
      tapCompleter!.complete("cancel");
    }

    showSummaryDialog();
    await speakSummary();

    setState(() {
      isSessionActive = false;
      isListening = false;
      bgdColor = const Color(0xFF364B9A);
    });
  }

  Future<void> readQuestion() async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;

    // setState(() {
    //   showDefinition = false;
    // });
    String question =
        widget.setToStudy.flashCards[currentQuestionIndex].question;
    await TTSSettings.tts.speak("The correct answer is: $question");
    attempts = 1;
  }

  Future<void> readAnswer(int number) async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;

    String answer = widget.setToStudy.flashCards[currentQuestionIndex].answer;
    setState(() {
      bgdColor = Colors.black;
    });
    await TTSSettings.tts.speak("Number $number : $answer");
    setState(() {
      bgdColor = const Color(0xFF364B9A);
    });
  }

  Future<void> speakSummary() async {
    await TTSSettings.tts.speak("Do you want to hear your session summary?");
    await Future.delayed(const Duration(milliseconds: 500));

    String response = await STTService().listenOnce();

    if (response.contains("yes") || response.contains("sure")) {
      await TTSSettings.tts.speak(
        "You got $correctAnswers correct and $wrongAnswers wrong out of ${correctAnswers + wrongAnswers} flashcards.",
      );
    } else {
      await TTSSettings.tts.speak("Okay. Bye!");
    }
  }

  void showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Session Summary"),
          content: Text(
            "Correct: $correctAnswers\nWrong: $wrongAnswers\nTotal: ${wrongAnswers + correctAnswers}",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
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
    int safeIndex = currentQuestionIndex;

    if (safeIndex >= widget.setToStudy.flashCards.length) {
      safeIndex = widget.setToStudy.flashCards.length - 1;
    }

    return GestureDetector(
      onTap: () {
        if (tapCompleter != null && !tapCompleter!.isCompleted) {
          tapCompleter!.complete("tap");
        }
        setState(() {
          // tap = true;
          // doubleTap = false;
        });
      },
      onDoubleTap: () {
        if (tapCompleter != null && !tapCompleter!.isCompleted) {
          tapCompleter!.complete("double");
        }
        setState(() {
          // doubleTap = true;
          // tap = false;
        });
      },
      child: Scaffold(
        backgroundColor: bgdColor,

        /// appBar: AppBar(title: Text("Study Session"), centerTitle: true),
        appBar: AppBar(
          backgroundColor: const Color(0xFF364B9A),
          foregroundColor: Colors.white,
          title: Text("Study Session"),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  backgroundColor: const Color(0xFFFDB366), // orange
                  foregroundColor: const Color(0xFF364B9A), // navy text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.settings, size: 24),
                label: const Text(
                  "Settings",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(onNameChanged: (name) {}),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Studying: ${widget.setToStudy.name}",
              style: TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Tap the card to show the answer",
              style: TextStyle(fontSize: 26, color: Colors.white70),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                setState(() {
                  showDefinition = !showDefinition;
                });
              },
              child: Card(
                color: const Color(0xFFFDB366),
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      showDefinition
                          ? Text(
                              widget.setToStudy.flashCards[safeIndex].answer,
                              style: TextStyle(
                                fontSize: 30,
                                color: const Color(
                                  0xFF364B9A,
                                ), // navy text on orange
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              widget.setToStudy.flashCards[safeIndex].question,
                              style: TextStyle(
                                fontSize: 65,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF364B9A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
              ),
            ),

            Text(
              "${safeIndex + 1} of ${widget.setToStudy.flashCards.length}",
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
                        showDefinition = false;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (currentQuestionIndex <
                          widget.setToStudy.flashCards.length - 1) {
                        currentQuestionIndex++;
                        showDefinition = false;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                ),
              ],
            ),

            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDB366), // orange
                foregroundColor: const Color(0xFF364B9A), // navy text
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
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

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value:
                          (safeIndex + 1) / widget.setToStudy.flashCards.length,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: const Color(0xFFFDB366),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "${(((safeIndex + 1) / widget.setToStudy.flashCards.length) * 100).round()}% completed",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFDB366),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
