import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'study_set.dart';

// class CardPage {
//   final String id;
//   final String question;
//   final String answer;

//   CardPage({required this.id, required this.question, required this.answer});
// }

class CardPage extends StatefulWidget {
  // String setName = '';
  // String setId = '';
  final StudySet cardSet;

  const CardPage({super.key, required this.cardSet});

  @override
  State<CardPage> createState() => CardPageState();
}

class CardPageState extends State<CardPage> {
  // int numerOfCards = 0;
  // List<FlashCard> flashCards = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cardSet.name), centerTitle: true),
      body: Column(
        children: [
          IconButton(
            icon: Icon(Icons.add),
            alignment: Alignment.center,
            onPressed: () {
              setState(() {
                widget.cardSet.flashCards.add(
                  FlashCard(
                    id: widget.cardSet.flashCards.length.toString(),
                    question: '',
                    answer: '',
                  ),
                );
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.cardSet.flashCards.length,
              itemBuilder: (context, index) {
                return FlashCardWidget(
                  onDeleteCard: (flashCard) {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                         content: const Text(
                           'Are you sure you want to delete this flash card?',
                           style: TextStyle(fontSize: 20),
                           textAlign: TextAlign.center,
                         ),
                        
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  widget.cardSet.flashCards.removeWhere(
                                    (card) => card.id == flashCard.id,
                                  );
                                });
                                Navigator.pop(dialogContext);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  flashCard: widget.cardSet.flashCards[index],
                  key: ValueKey(widget.cardSet.flashCards[index].id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
