import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'study_set.dart';
import 'study_session.dart';

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
          //     IconButton(
          //    icon: Icon(Icons.add),
          //  alignment: Alignment.center,
          //   onPressed: () {
          //     setState(() {
          //       widget.cardSet.flashCards.add(
          //         FlashCard(
          //            id: widget.cardSet.flashCards.length.toString(),
          //            question: '',
          //            answer: '',
          //          ),
          //        );
          //      });
          //    },
          //   ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                iconSize: 30,
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

              const SizedBox(width: 8),

              GestureDetector(
                onTap: () {
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
                child: Text(
                  "Add Card",
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          //StudySession(setToStudy: widget.cardSet),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudySessionScreen(setToStudy: widget.cardSet),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Start Session",
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
