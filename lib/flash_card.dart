import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlashCard {
  final String id;
  final String question;
  final String answer;

  FlashCard({required this.id, required this.question, required this.answer});
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
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a question',
                      labelText: 'Question',
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
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter the answer',
                      labelText: 'Answer',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
