import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assisted_learning/services/tts_service.dart';
import 'services/stt_service.dart';
import 'widgets/accessible_mic_button.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlashCard {
  final String id;
  String question;
  String answer;
  bool isEditing;

  FlashCard({
    required this.id,
    required this.question,
    required this.answer,
    this.isEditing = true,
  });
}

class FlashCardWidget extends StatefulWidget {
  final FlashCard flashCard;
  final void Function(FlashCard flashCard)? onDeleteCard;

  const FlashCardWidget({
    super.key,
    required this.flashCard,
    this.onDeleteCard,
  });

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> {
  late final TextEditingController questionController;
  late final TextEditingController answerController;

  final stt = STTService();
  bool isListeningAnswer = false;
  bool isListeningQuestion = false;

  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController(text: widget.flashCard.question);
    answerController = TextEditingController(text: widget.flashCard.answer);
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    super.dispose();
  }

  void _onDonePressed() {
    setState(() {
      widget.flashCard.isEditing = false;
      widget.flashCard.question = questionController.text;
      widget.flashCard.answer = answerController.text;
    });
  }

  Future<void> _toggleQuestionMic() async {
    if (!isListeningQuestion) {
      final available = await stt.initialize();
      if (!available) {
        await tts.speak('Microphone not available. Please check permissions.');
        return;
      }
      await tts.speak('Microphone on. Speak the word.');
      setState(() => isListeningQuestion = true);
      await stt.listen(
        onResult: (text) => setState(() => questionController.text = text),
      );
    } else {
      await tts.speak('Microphone off.');
      await stt.stopListening();
      setState(() => isListeningQuestion = false);
    }
  }

  Future<void> _toggleAnswerMic() async {
    if (!isListeningAnswer) {
      final available = await stt.initialize();
      if (!available) {
        await tts.speak('Microphone not available. Please check permissions.');
        return;
      }
      await tts.speak('Microphone on. Speak the definition.');
      setState(() => isListeningAnswer = true);
      await stt.listen(
        onResult: (text) => setState(() => answerController.text = text),
      );
    } else {
      await tts.speak('Microphone off.');
      await stt.stopListening();
      setState(() => isListeningAnswer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Give the whole card a summary label when not editing,
      // so VoiceOver reads "Flash card: Supply. Definition: Amount of a
      // product available." as a single unit.
      label: widget.flashCard.isEditing
          ? 'Edit flash card'
          : 'Flash card: ${widget.flashCard.question}. '
                'Definition: ${widget.flashCard.answer}',
      container: true,
      child: Card(
        color: const Color(0xFFFDB366),
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Word / Question row ──────────────────────────────
              if (widget.flashCard.isEditing)
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Word field',
                        textField: true,
                        child: TextField(
                          controller: questionController,
                          style: const TextStyle(
                            color: Color(0xFF364B9A),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter a word',
                            hintStyle: TextStyle(color: Color(0xFF364B9A)),
                            labelText: 'Word',
                            labelStyle: TextStyle(color: Color(0xFF364B9A)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AccessibleMicButton(
                      isListening: isListeningQuestion,
                      fieldLabel: 'word',
                      onTap: _toggleQuestionMic,
                    ),
                  ],
                )
              else
                ExcludeSemantics(
                  // Excluded because the parent Semantics container
                  // already reads word + definition together
                  child: Text(
                    widget.flashCard.question,
                    style: const TextStyle(
                      color: Color(0xFF364B9A),
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              // ── Definition / Answer row ──────────────────────────
              if (widget.flashCard.isEditing)
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Definition field',
                        textField: true,
                        child: TextField(
                          controller: answerController,
                          style: const TextStyle(
                            color: Color(0xFF364B9A),
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter the definition',
                            hintStyle: TextStyle(color: Color(0xFF364B9A)),
                            labelText: 'Definition',
                            labelStyle: TextStyle(color: Color(0xFF364B9A)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AccessibleMicButton(
                      isListening: isListeningAnswer,
                      fieldLabel: 'definition',
                      onTap: _toggleAnswerMic,
                    ),
                  ],
                )
              else
                ExcludeSemantics(
                  child: Text(
                    widget.flashCard.answer,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF364B9A),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Action buttons row ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.flashCard.isEditing)
                    Semantics(
                      button: true,
                      label: 'Save card',
                      child: TextButton(
                        onPressed: _onDonePressed,
                        child: const Text('Done'),
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      label: 'Delete this card',
                      hint: 'Removes ${widget.flashCard.question} from the set',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          iconSize: 30,
                          tooltip: 'Delete card',
                          onPressed: () {
                            if (widget.onDeleteCard != null) {
                              widget.onDeleteCard!(widget.flashCard);
                            }
                          },
                        ),
                      ),
                    ),

                  Semantics(
                    button: true,
                    label:
                        'Read aloud: ${widget.flashCard.question}, ${widget.flashCard.answer}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.white),
                        iconSize: 40,
                        tooltip: 'Read card aloud',
                        onPressed: () async {
                          await TTSSettings.tts.speak(
                            '${widget.flashCard.question}: '
                            '${widget.flashCard.answer}',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
