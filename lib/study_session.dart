import 'study_set.dart';
import 'profile_screen.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'services/semantics_announcer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'services/answer_matcher.dart';
import 'services/progress_service.dart';

class StudySessionScreen extends StatefulWidget {
  final StudySet setToStudy;

  const StudySessionScreen({super.key, required this.setToStudy});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  bool isSessionActive = false;
  int currentQuestionIndex = 0;
  int num = 1;
  Color bgdColor = const Color(0xFF364B9A);
  bool showDefinition = false;

  int correctAnswers = 0;
  int wrongAnswers = 0;
  int attempts = 0;

  Completer<String>? tapCompleter;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    TTSSettings.tts.setSpeechRate(TTSSettings.speechRate);
    STTService().initialize();
  }

  @override
  void dispose() {
    // Cancel any pending tap completer so async chains don't run after dispose
    if (tapCompleter != null && !tapCompleter!.isCompleted) {
      tapCompleter!.complete('cancel');
    }
    super.dispose();
  }

  // ─── Session control ──────────────────────────────────────────────────────

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

    // Announce to screen reader as well as TTS
    SemanticsAnnouncer.announce(
      'Study session started for ${widget.setToStudy.name}.',
      assertive: true,
    );

    await TTSSettings.tts.speak(
      'Starting study session for ${widget.setToStudy.name}.',
    );
    await runQuestion(false);
  }

  Future<void> runQuestion(bool isRetrying) async {
    if (!isSessionActive || !mounted) return;

    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) {
      await TTSSettings.tts.speak('Congratulations! You finished!');
      SemanticsAnnouncer.announce('Session complete!', assertive: true);
      endSession();
      return;
    }

    setState(() => showDefinition = true);

    if (!isRetrying) {
      attempts = 1;
      await readAnswer(num);
    } else {
      attempts++;
    }

    setState(() => bgdColor = Colors.blue);

    final userAnswer = await STTService().listenOnce();
    if (!isSessionActive || !mounted) return;

    await handleAnswer(userAnswer);
  }

  Future<void> handleAnswer(String userAnswer) async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;

    final expectedAnswer =
        widget.setToStudy.flashCards[currentQuestionIndex].question;

    // ── Stop command ─────────────────────────────────────────────────────────
    if (userAnswer.contains('stop')) {
      await TTSSettings.tts.speak('Study session ended. Great job!');
      endSession();
      return;
    }

    // ── No answer / don't know ───────────────────────────────────────────────
    if (userAnswer.isEmpty || userAnswer.contains("don't know")) {
      setState(() => bgdColor = Colors.black);

      if (userAnswer.contains("don't know")) {
        await TTSSettings.tts.speak(
          'No worries, do you want to hear the correct answer?',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => bgdColor = Colors.blue);

        final yesOrNo = await STTService().listenOnce();

        if (yesOrNo.contains('yes') || yesOrNo.contains('sure')) {
          await readQuestion();
          if (attempts == 1) {
            wrongAnswers++;
            await ProgressService.recordWrong(
              widget.setToStudy,
              widget.setToStudy.flashCards[currentQuestionIndex],
            );
          }
          setState(() => currentQuestionIndex++);
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
        return;
      }

      await TTSSettings.tts.speak(
        'Do you need help? Tap the screen to hear the correct answer, '
        'or double tap to keep trying.',
      );

      tapCompleter = Completer<String>();
      final action = await tapCompleter!.future;

      if (action == 'tap') {
        await readQuestion();
        setState(() {
          currentQuestionIndex++;
          showDefinition = false;
          if (attempts == 1) wrongAnswers++;
        });
        num++;
        if (currentQuestionIndex <= widget.setToStudy.flashCards.length) {
          await runQuestion(false);
        }
      } else if (action == 'double') {
        await runQuestion(true);
      }
      return;
    }

    // ── Fuzzy match ──────────────────────────────────────────────────────────
    final result = AnswerMatcher.match(userAnswer, expectedAnswer);
    print('Match result: $result');

    if (result.isCorrect) {
      // ── Correct (exact, close, or stem match) ────────────────────────────
      setState(() {
        bgdColor = Colors.green;
        if (attempts == 1) correctAnswers++;
      });
      if (attempts == 1) {
        await ProgressService.recordCorrect(
          widget.setToStudy,
          widget.setToStudy.flashCards[currentQuestionIndex],
        );
      }

      // Give slightly different feedback depending on how close it was
      if (result.score == 1.0) {
        SemanticsAnnouncer.announce('Correct!', assertive: true);
        await TTSSettings.tts.speak('Correct!');
      } else {
        // They were close — confirm the exact answer so they learn it
        SemanticsAnnouncer.announce(
          'Correct! The answer is $expectedAnswer.',
          assertive: true,
        );
        await TTSSettings.tts.speak(
          'Correct! The exact answer is $expectedAnswer.',
        );
      }

      setState(() => currentQuestionIndex++);
      num++;

      await Future.delayed(const Duration(milliseconds: 500));
      if (currentQuestionIndex <= widget.setToStudy.flashCards.length) {
        await runQuestion(false);
      }
    } else if (AnswerMatcher.isAlmostCorrect(result)) {
      // ── Almost correct — give a nudge instead of just "try again" ────────
      setState(() => bgdColor = Colors.orange);

      SemanticsAnnouncer.announce(
        "Almost! You said $userAnswer. Try once more.",
        assertive: true,
      );
      await TTSSettings.tts.speak(
        "Almost! You said $userAnswer. Try saying it once more.",
      );

      await runQuestion(true);
    } else {
      // ── Wrong ────────────────────────────────────────────────────────────
      setState(() {
        bgdColor = Colors.red;
        if (attempts == 1) wrongAnswers++;
      });
      if (attempts == 1) {
        await ProgressService.recordWrong(
          widget.setToStudy,
          widget.setToStudy.flashCards[currentQuestionIndex],
        );
      }

      SemanticsAnnouncer.announce('Incorrect. Try again.', assertive: true);
      await TTSSettings.tts.speak('Try again!');
      await runQuestion(true);
    }
  }

  Future<void> endSession() async {
    TTSSettings.tts.stop();
    await STTService().stopListening();

    if (tapCompleter != null && !tapCompleter!.isCompleted) {
      tapCompleter!.complete('cancel');
    }

    if (mounted) {
      showSummaryDialog();
      await speakSummary();
    }

    setState(() {
      isSessionActive = false;
      isListening = false;
      bgdColor = const Color(0xFF364B9A);
    });
  }

  Future<void> readQuestion() async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;
    final question =
        widget.setToStudy.flashCards[currentQuestionIndex].question;
    await TTSSettings.tts.speak('The correct answer is: $question');
    attempts = 1;
  }

  Future<void> readAnswer(int number) async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;
    final answer = widget.setToStudy.flashCards[currentQuestionIndex].answer;
    setState(() => bgdColor = Colors.black);
    await TTSSettings.tts.speak('Number $number: $answer');
    setState(() => bgdColor = const Color(0xFF364B9A));
  }

  Future<void> speakSummary() async {
    await TTSSettings.tts.speak('Do you want to hear your session summary?');
    await Future.delayed(const Duration(milliseconds: 500));

    final response = await STTService().listenOnce();
    if (response.contains('yes') || response.contains('sure')) {
      final total = correctAnswers + wrongAnswers;
      await TTSSettings.tts.speak(
        'You got $correctAnswers correct and $wrongAnswers wrong '
        'out of $total flashcards.',
      );
    } else {
      await TTSSettings.tts.speak('Okay. Bye!');
    }
  }

  void showSummaryDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => Semantics(
        label: 'Session summary dialog',
        child: AlertDialog(
          title: const Text('Session Summary'),
          content: Semantics(
            label:
                'You got $correctAnswers correct and $wrongAnswers wrong '
                'out of ${correctAnswers + wrongAnswers} cards.',
            child: Text(
              'Correct: $correctAnswers\n'
              'Wrong: $wrongAnswers\n'
              'Total: ${correctAnswers + wrongAnswers}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Close summary',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentQuestionIndex.clamp(
      0,
      widget.setToStudy.flashCards.length - 1,
    );

    final currentCard = widget.setToStudy.flashCards[safeIndex];
    final progressPercent =
        ((safeIndex + 1) / widget.setToStudy.flashCards.length * 100).round();

    return GestureDetector(
      onTap: () {
        if (tapCompleter != null && !tapCompleter!.isCompleted) {
          tapCompleter!.complete('tap');
        }
      },
      onDoubleTap: () {
        if (tapCompleter != null && !tapCompleter!.isCompleted) {
          tapCompleter!.complete('double');
        }
      },
      child: Scaffold(
        backgroundColor: bgdColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF364B9A),
          foregroundColor: Colors.white,
          title: Semantics(
            header: true,
            child: Text('Study Session — ${widget.setToStudy.name}'),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                button: true,
                label: 'Open settings',
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    backgroundColor: const Color(0xFFFDB366),
                    foregroundColor: const Color(0xFF364B9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.settings, size: 24),
                  label: const Text(
                    'Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(onNameChanged: (name) {}),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Header text ─────────────────────────────────────
            ExcludeSemantics(
              // Covered by the AppBar title
              child: Text(
                'Studying: ${widget.setToStudy.name}',
                style: const TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 5),
            ExcludeSemantics(
              child: Text(
                'Tap the card to show the answer',
                style: const TextStyle(fontSize: 26, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 30),

            // ── Flash card ──────────────────────────────────────
            Semantics(
              label: showDefinition
                  ? 'Definition: ${currentCard.answer}. Tap to show word.'
                  : 'Word: ${currentCard.question}. Tap to show definition.',
              button: true,
              hint: 'Double tap to flip card',
              child: GestureDetector(
                onTap: () => setState(() => showDefinition = !showDefinition),
                child: Card(
                  color: const Color(0xFFFDB366),
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ExcludeSemantics(
                        // Parent Semantics handles the label
                        child: Text(
                          showDefinition
                              ? currentCard.answer
                              : currentCard.question,
                          style: TextStyle(
                            fontSize: showDefinition ? 30 : 65,
                            fontWeight: showDefinition
                                ? FontWeight.normal
                                : FontWeight.w900,
                            color: const Color(0xFF364B9A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Progress indicator ──────────────────────────────
            Semantics(
              label:
                  'Card ${safeIndex + 1} of '
                  '${widget.setToStudy.flashCards.length}',
              child: Text(
                '${safeIndex + 1} of ${widget.setToStudy.flashCards.length}',
                style: const TextStyle(fontSize: 25, color: Colors.white),
              ),
            ),
            const SizedBox(height: 5),

            // ── Navigation arrows ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Previous card',
                  enabled: currentQuestionIndex > 0,
                  child: IconButton(
                    onPressed: currentQuestionIndex > 0
                        ? () => setState(() {
                            currentQuestionIndex--;
                            showDefinition = false;
                          })
                        : null,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    tooltip: 'Previous card',
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Next card',
                  enabled:
                      currentQuestionIndex <
                      widget.setToStudy.flashCards.length - 1,
                  child: IconButton(
                    onPressed:
                        currentQuestionIndex <
                            widget.setToStudy.flashCards.length - 1
                        ? () => setState(() {
                            currentQuestionIndex++;
                            showDefinition = false;
                          })
                        : null,
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    tooltip: 'Next card',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Start / End session button ──────────────────────
            Semantics(
              button: true,
              label: isSessionActive
                  ? 'End study session'
                  : 'Start study session',
              hint: isSessionActive
                  ? 'Stops the audio study session'
                  : 'Begins audio study session for '
                        '${widget.setToStudy.name}',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDB366),
                  foregroundColor: const Color(0xFF364B9A),
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
                onPressed: () {
                  if (isSessionActive) {
                    endSession();
                  } else {
                    startSession();
                  }
                },
                child: Text(isSessionActive ? 'End Session' : 'Start Session'),
              ),
            ),

            const SizedBox(height: 30),

            // ── Progress bar ────────────────────────────────────
            Semantics(
              label: '$progressPercent percent completed',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value:
                            (safeIndex + 1) /
                            widget.setToStudy.flashCards.length,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFFFDB366),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExcludeSemantics(
                      child: Text(
                        '$progressPercent% completed',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFDB366),
                        ),
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
