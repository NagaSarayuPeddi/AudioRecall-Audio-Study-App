import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'services/stt_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlashCard {
  final String id;
  String question;
  String answer;
  bool isEditing = true; // controls Done vs Trash

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
  TextEditingController? questionController;
  TextEditingController? answerController;

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

  void onDonePressed() {
    // Logic for when the Done button is pressed
    setState(() {
      widget.flashCard.isEditing = false;
      widget.flashCard.question = questionController!.text;
      widget.flashCard.answer = answerController!.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Q:", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 10),
                Expanded(
                  child: widget.flashCard.isEditing
                      ? TextField(
                          controller: questionController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter a question',
                            labelText: 'Question',
                          ),
                        )
                      : Text(
                          widget.flashCard.question,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!isListeningQuestion) {
                      // Initialize speech-to-text first
                      bool available = await stt.initialize();
                      if (!available) {
                        print("Microphone not available or permission denied");
                        return;
                      }
                      await tts.speak(
                        "Microphone activated. Start speaking the question.",
                      );
                      // Start listening
                      setState(() => isListeningQuestion = true);
                      stt.startListening((text) {
                        setState(() {
                          questionController!.text = text;
                        });
                      });
                    } else {
                      await tts.speak("Microphone deactivated.");
                      // Stop listening
                      stt.stopListening();
                      setState(() => isListeningQuestion = false);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isListeningQuestion ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text("A:", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 10),
                Expanded(
                  child: widget.flashCard.isEditing
                      ? TextField(
                          controller: answerController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter the answer',
                            labelText: 'Answer',
                          ),
                        )
                      : Text(
                          widget.flashCard.answer,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!isListeningAnswer) {
                      // Initialize speech-to-text first
                      bool available = await stt.initialize();
                      if (!available) {
                        print("Microphone not available or permission denied");
                        return;
                      }

                      await tts.speak(
                        "Microphone activated. Start speaking the answer.",
                      );

                      // Start listening
                      setState(() => isListeningAnswer = true);
                      stt.startListening((text) {
                        setState(() {
                          answerController!.text = text;
                        });
                      });
                    } else {
                      await tts.speak("Microphone deactivated.");
                      // Stop listening
                      stt.stopListening();
                      setState(() => isListeningAnswer = false);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isListeningAnswer ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.flashCard.isEditing)
              TextButton(onPressed: onDonePressed, child: Text("Done"))
            else
              IconButton(
                icon: Icon(Icons.delete),
                color: Colors.red,
                onPressed: () {
                  if (widget.onDeleteCard != null) {
                    widget.onDeleteCard!(widget.flashCard);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
