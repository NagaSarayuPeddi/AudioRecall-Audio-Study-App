//import 'widgets/study_set.dart';
import 'sets_screen.dart';
import 'profile_screen.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'services/semantics_announcer.dart';
import 'services/answer_matcher.dart';
import 'services/progress_service.dart';
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
  int currentQuestionIndex = 0;
  int num = 1;

  // Only the flash card changes colour — not the whole screen
  Color _cardAccentColor = const Color(0xFFFDB366);

  bool showDefinition = false;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int attempts = 0;

  Completer<String>? tapCompleter;

  @override
  void initState() {
    super.initState();
    TTSSettings.tts.setSpeechRate(TTSSettings.speechRate);
    STTService().initialize();
  }

  @override
  void dispose() {
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
      showDefinition = true;
      _cardAccentColor = const Color(0xFFFDB366);
    });

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
      await _readAnswer(num);
    } else {
      attempts++;
    }

    setState(() => _cardAccentColor = const Color(0xFFFDB366));

    final userAnswer = await STTService().listenOnce();
    if (!isSessionActive || !mounted) return;

    await handleAnswer(userAnswer);
  }

  Future<void> handleAnswer(String userAnswer) async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;

    final card = widget.setToStudy.flashCards[currentQuestionIndex];
    final expectedAnswer = card.question;

    if (userAnswer.contains('stop')) {
      await TTSSettings.tts.speak('Study session ended. Great job!');
      endSession();
      return;
    }

    if (userAnswer.isEmpty || userAnswer.contains("don't know")) {
      setState(() => _cardAccentColor = Colors.grey.shade300);

      if (userAnswer.contains("don't know")) {
        await TTSSettings.tts.speak(
          'No worries, do you want to hear the correct answer?',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _cardAccentColor = const Color(0xFFFDB366));

        final yesOrNo = await STTService().listenOnce();
        if (yesOrNo.contains('yes') || yesOrNo.contains('sure')) {
          await _readQuestion();
          if (attempts == 1) {
            wrongAnswers++;
            await ProgressService.recordWrong(widget.setToStudy, card);
          }
          setState(() => currentQuestionIndex++);
          num++;
          await Future.delayed(const Duration(milliseconds: 500));
          await runQuestion(false);
        } else {
          await TTSSettings.tts.speak("Okay, let's try again.");
          await runQuestion(true);
        }
        return;
      }

      await TTSSettings.tts.speak(
        'Tap the screen to hear the answer, or double tap to keep trying.',
      );
      SemanticsAnnouncer.announce('Tap once for answer, double tap to retry.');

      tapCompleter = Completer<String>();
      final action = await tapCompleter!.future;

      if (action == 'tap') {
        await _readQuestion();
        setState(() {
          currentQuestionIndex++;
          showDefinition = false;
          if (attempts == 1) wrongAnswers++;
        });
        if (attempts == 1) {
          await ProgressService.recordWrong(widget.setToStudy, card);
        }
        num++;
        await runQuestion(false);
      } else if (action == 'double') {
        await runQuestion(true);
      }
      return;
    }

    // ── Fuzzy match ──────────────────────────────────────────────────────────
    final result = AnswerMatcher.match(userAnswer, expectedAnswer);

    if (result.isCorrect) {
      setState(() {
        _cardAccentColor = const Color(0xFF4CAF50);
        if (attempts == 1) correctAnswers++;
      });
      if (attempts == 1) {
        await ProgressService.recordCorrect(widget.setToStudy, card);
      }

      SemanticsAnnouncer.announce('Correct!', assertive: true);
      if (result.score < 1.0) {
        await TTSSettings.tts.speak(
          'Correct! The exact answer is $expectedAnswer.',
        );
      } else {
        await TTSSettings.tts.speak('Correct!');
      }

      setState(() => currentQuestionIndex++);
      num++;
      await Future.delayed(const Duration(milliseconds: 500));
      await runQuestion(false);
    } else if (AnswerMatcher.isAlmostCorrect(result)) {
      setState(() => _cardAccentColor = Colors.orange.shade300);
      SemanticsAnnouncer.announce('Almost! Try once more.', assertive: true);
      await TTSSettings.tts.speak(
        'Almost! You said $userAnswer. Try once more.',
      );
      await runQuestion(true);
    } else {
      setState(() {
        _cardAccentColor = Colors.red.shade300;
        if (attempts == 1) wrongAnswers++;
      });
      if (attempts == 1) {
        await ProgressService.recordWrong(widget.setToStudy, card);
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
      _showSummaryDialog();
      await _speakSummary();
    }
    setState(() {
      isSessionActive = false;
      _cardAccentColor = const Color(0xFFFDB366);
    });
  }

  Future<void> _readQuestion() async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;
    final q = widget.setToStudy.flashCards[currentQuestionIndex].question;
    await TTSSettings.tts.speak('The correct answer is: $q');
    attempts = 1;
  }

  Future<void> _readAnswer(int number) async {
    if (currentQuestionIndex >= widget.setToStudy.flashCards.length) return;
    final a = widget.setToStudy.flashCards[currentQuestionIndex].answer;
    await TTSSettings.tts.speak('Number $number: $a');
  }

  Future<void> _speakSummary() async {
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

  void _showSummaryDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session summary'),
        content: Text(
          'Correct: $correctAnswers\n'
          'Wrong: $wrongAnswers\n'
          'Total: ${correctAnswers + wrongAnswers}',
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.setToStudy.flashCards;
    final safeIndex = currentQuestionIndex.clamp(0, cards.length - 1);
    final currentCard = cards[safeIndex];
    final progress = (safeIndex + 1) / cards.length;
    final progressPercent = (progress * 100).round();

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
        // Fixed: always navy — card changes colour, not the whole screen
        backgroundColor: const Color(0xFF364B9A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF364B9A),
          foregroundColor: Colors.white,
          title: Text(
            widget.setToStudy.name,
            style: const TextStyle(fontSize: 25),
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            Semantics(
              button: true,
              label: 'Open settings',
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(onNameChanged: (_) {}),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // ── Flash card ──────────────────────────────────
                Semantics(
                  label: showDefinition
                      ? 'Definition: ${currentCard.answer}. Tap to show word.'
                      : 'Word: ${currentCard.question}. Tap to show definition.',
                  button: true,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => showDefinition = !showDefinition),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      // Fixed height so the card doesn't grow/shrink
                      height: 220,
                      decoration: BoxDecoration(
                        color: _cardAccentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ExcludeSemantics(
                          // FittedBox prevents long words overflowing
                          // child: FittedBox(
                          //fit: BoxFit.scaleDown,
                          child: Text(
                            showDefinition
                                ? currentCard.answer
                                : currentCard.question,
                            style: TextStyle(
                              fontSize: showDefinition ? 22 : 48,
                              fontWeight: showDefinition
                                  ? FontWeight.normal
                                  : FontWeight.w900,
                              color: const Color(0xFF364B9A),
                            ),
                            textAlign: TextAlign.center,
                            //maxLines: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Hint text ───────────────────────────────────
                Text(
                  'Tap card to flip',
                  style: TextStyle(
                    fontSize: 13,
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Navigation row ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Previous card',
                      child: IconButton(
                        onPressed: currentQuestionIndex > 0
                            ? () => setState(() {
                                currentQuestionIndex--;
                                showDefinition = false;
                              })
                            : null,
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        tooltip: 'Previous',
                      ),
                    ),
                    Text(
                      '${safeIndex + 1} / ${cards.length}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Semantics(
                      button: true,
                      label: 'Next card',
                      child: IconButton(
                        onPressed: currentQuestionIndex < cards.length - 1
                            ? () => setState(() {
                                currentQuestionIndex++;
                                showDefinition = false;
                              })
                            : null,
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                        tooltip: 'Next',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Progress bar ────────────────────────────────
                Semantics(
                  label: '$progressPercent percent completed',
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: const Color(0xFFFDB366),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$progressPercent% complete',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Start / End button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDB366),
                      foregroundColor: const Color(0xFF364B9A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (isSessionActive) {
                        endSession();
                      } else {
                        startSession();
                      }
                    },
                    child: Text(
                      isSessionActive ? 'End session' : 'Start session',
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
