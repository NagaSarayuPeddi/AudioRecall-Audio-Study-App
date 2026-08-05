import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'profile_screen.dart';
//import 'widgets/study_set.dart';
import 'sets_screen.dart';
import 'study_session.dart';
import 'progress_screen.dart';

class CardPage extends StatefulWidget {
  final StudySet cardSet;
  const CardPage({super.key, required this.cardSet});

  @override
  State<CardPage> createState() => CardPageState();
}

class CardPageState extends State<CardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF364B9A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cardSet.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.cardSet.flashCards.length} cards',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          // Progress button
          Semantics(
            button: true,
            label: 'View progress',
            child: IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: 'Progress',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgressScreen(set: widget.cardSet),
                ),
              ),
            ),
          ),

          // Overflow menu for Settings (keeps AppBar clean)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(onNameChanged: (_) {}),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top action bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                // Start study session
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudySessionScreen(setToStudy: widget.cardSet),
                      ),
                    ),
                    icon: const Icon(Icons.headphones_outlined, size: 18),
                    label: const Text('Study'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDB366),
                      foregroundColor: const Color(0xFF364B9A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Add card
                Semantics(
                  button: true,
                  label: 'Add a new card',
                  child: OutlinedButton.icon(
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
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Card list ──────────────────────────────────────
          Expanded(
            child: widget.cardSet.flashCards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.style_outlined,
                          size: 48,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No cards yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add card" to get started',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: widget.cardSet.flashCards.length,
                    itemBuilder: (context, index) {
                      return FlashCardWidget(
                        key: ValueKey(widget.cardSet.flashCards[index].id),
                        flashCard: widget.cardSet.flashCards[index],
                        onDeleteCard: (card) {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              content: const Text(
                                'Delete this card?',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      widget.cardSet.flashCards.removeWhere(
                                        (c) => c.id == card.id,
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
                            ),
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
