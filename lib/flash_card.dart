import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:AudioRecall/services/tts_service.dart';
import 'package:AudioRecall/services/stt_service.dart';
import 'package:AudioRecall/widgets/accessible_mic_button.dart';

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
        await TTSSettings.tts.speak('Microphone not available.');
        return;
      }
      await TTSSettings.tts.speak('Speak the word.');
      setState(() => isListeningQuestion = true);
      await stt.listen(
        onResult: (t) => setState(() => questionController.text = t),
      );
    } else {
      await stt.stopListening();
      setState(() => isListeningQuestion = false);
    }
  }

  Future<void> _toggleAnswerMic() async {
    if (!isListeningAnswer) {
      final available = await stt.initialize();
      if (!available) {
        await TTSSettings.tts.speak('Microphone not available.');
        return;
      }
      await TTSSettings.tts.speak('Speak the definition.');
      setState(() => isListeningAnswer = true);
      await stt.listen(
        onResult: (t) => setState(() => answerController.text = t),
      );
    } else {
      await stt.stopListening();
      setState(() => isListeningAnswer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.flashCard.isEditing
          ? 'Edit flash card'
          : 'Flash card: ${widget.flashCard.question}. '
                'Definition: ${widget.flashCard.answer}',
      container: true,
      child: Card(
        color: const Color(0xFFFDB366),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Word row ────────────────────────────────────
              if (widget.flashCard.isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: questionController,
                        style: const TextStyle(
                          color: Color(0xFF364B9A),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter a word',
                          hintStyle: TextStyle(color: Color(0xFF364B9A)),
                          labelText: 'Word',
                          labelStyle: TextStyle(color: Color(0xFF364B9A)),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Fixed: 48×48 instead of 80×80
                    AccessibleMicButton(
                      isListening: isListeningQuestion,
                      fieldLabel: 'word',
                      onTap: _toggleQuestionMic,
                      size: 48,
                    ),
                  ],
                )
              else
                ExcludeSemantics(
                  child: Text(
                    widget.flashCard.question,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF364B9A),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Definition row ──────────────────────────────
              if (widget.flashCard.isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: answerController,
                        style: const TextStyle(
                          color: Color(0xFF364B9A),
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter the definition',
                          hintStyle: TextStyle(color: Color(0xFF364B9A)),
                          labelText: 'Definition',
                          labelStyle: TextStyle(color: Color(0xFF364B9A)),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AccessibleMicButton(
                      isListening: isListeningAnswer,
                      fieldLabel: 'definition',
                      onTap: _toggleAnswerMic,
                      size: 48,
                    ),
                  ],
                )
              else
                ExcludeSemantics(
                  child: Text(
                    widget.flashCard.answer,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF364B9A),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Action row ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.flashCard.isEditing)
                    TextButton(
                      onPressed: _onDonePressed,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF364B9A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      label: 'Delete this card',
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        iconSize: 22,
                        onPressed: () {
                          if (widget.onDeleteCard != null) {
                            widget.onDeleteCard!(widget.flashCard);
                          }
                        },
                        tooltip: 'Delete',
                      ),
                    ),

                  Semantics(
                    button: true,
                    label:
                        'Read aloud: ${widget.flashCard.question}, ${widget.flashCard.answer}',
                    child: IconButton(
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        color: Color(0xFF364B9A),
                      ),
                      iconSize: 22,
                      onPressed: () async {
                        await TTSSettings.tts.speak(
                          '${widget.flashCard.question}: '
                          '${widget.flashCard.answer}',
                        );
                      },
                      tooltip: 'Read aloud',
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
