import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'study_set.dart';
import 'study_session.dart';

class SetsScreen extends StatefulWidget {
  final List<StudySet> sets;

  const SetsScreen({super.key, required this.sets});

  @override
  State<SetsScreen> createState() => _SetsScreenState();
}

class _SetsScreenState extends State<SetsScreen> {
  int numberOfSets = 0;
  // List<StudySet> sets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(12, 123, 220, 10),
      appBar: AppBar(title: const Text('Sets')),
      body: Column(
        children: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                numberOfSets++;
                widget.sets.add(
                  StudySet(
                    id: numberOfSets.toString(),
                    name: '',
                    description: '',
                    flashCards: new List<FlashCard>.empty(growable: true),
                  ),
                );
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.sets.length,
              itemBuilder: (context, index) {
                return SetWidget(
                  key: ValueKey(widget.sets[index].id),
                  set: widget.sets[index],
                  onDelete: (setToDelete) {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          content: const Text(
                            'Are you sure you want to delete this set?',
                            style: TextStyle(fontSize: 20, color: Colors.black),
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
                                  widget.sets.removeWhere(
                                    (set_) => set_.id == setToDelete.id,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
