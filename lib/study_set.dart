import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'cards_page.dart';
import 'services/stt_service.dart';
import 'widgets/accessible_mic_button.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StudySet {
  String id;
  String name;
  String description;
  List<FlashCard> flashCards;
  bool isEditing;

  StudySet({
    required this.id,
    required this.name,
    required this.description,
    required this.flashCards,
    this.isEditing = true,
  });
}

class SetWidget extends StatefulWidget {
  final StudySet set;
  final void Function(StudySet set) onDelete;

  const SetWidget({super.key, required this.set, required this.onDelete});

  @override
  State<SetWidget> createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  final stt = STTService();
  bool isListeningDescription = false;
  bool isListeningName = false;

  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.set.name);
    descriptionController = TextEditingController(text: widget.set.description);
    stt.initialize();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _donePressed() {
    setState(() {
      widget.set.isEditing = false;
      widget.set.name = nameController.text;
      widget.set.description = descriptionController.text;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardPage(cardSet: widget.set)),
    );
  }

  Future<void> _toggleNameMic() async {
    if (!isListeningName) {
      await tts.speak('Microphone on. Speak the set name.');
      setState(() => isListeningName = true);
      await stt.listen(
        onResult: (text) => setState(() => nameController.text = text),
      );
    } else {
      await tts.speak('Microphone off.');
      await stt.stopListening();
      setState(() => isListeningName = false);
    }
  }

  Future<void> _toggleDescriptionMic() async {
    if (!isListeningDescription) {
      final available = await stt.initialize();
      if (!available) {
        await tts.speak('Microphone not available.');
        return;
      }
      await tts.speak('Microphone on. Speak the description.');
      setState(() => isListeningDescription = true);
      await stt.listen(
        onResult: (text) => setState(() => descriptionController.text = text),
      );
    } else {
      await tts.speak('Microphone off.');
      await stt.stopListening();
      setState(() => isListeningDescription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // When not editing, give the card a clear summary label
      label: widget.set.isEditing
          ? 'New study set'
          : 'Study set: ${widget.set.name}, '
                '${widget.set.flashCards.length} cards. '
                'Double tap to open.',
      button: !widget.set.isEditing,
      container: true,
      child: TextButton(
        onPressed: widget.set.isEditing
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardPage(cardSet: widget.set),
                ),
              ),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Card(
          color: const Color(0xFFFDB366),
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name row ──────────────────────────────────────
                if (widget.set.isEditing)
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          'Set Name: ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          label: 'Set name field',
                          textField: true,
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter set name',
                              labelText: 'Set Name',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AccessibleMicButton(
                        isListening: isListeningName,
                        fieldLabel: 'set name',
                        onTap: _toggleNameMic,
                      ),
                    ],
                  )
                else
                  // Shown set name with delete button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ExcludeSemantics(
                          // Parent Semantics node covers this
                          child: Text(
                            widget.set.name,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF364B9A),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Delete ${widget.set.name}',
                        hint: 'Permanently removes this study set',
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
                            tooltip: 'Delete set',
                            onPressed: () => widget.onDelete.call(widget.set),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                // ── Description row (editing only) ────────────────
                if (widget.set.isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Description field',
                          textField: true,
                          child: TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter description',
                              labelText: 'Description',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AccessibleMicButton(
                        isListening: isListeningDescription,
                        fieldLabel: 'description',
                        onTap: _toggleDescriptionMic,
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                // ── Done button ───────────────────────────────────
                if (widget.set.isEditing)
                  Semantics(
                    button: true,
                    label: 'Save set and add cards',
                    child: TextButton(
                      onPressed: _donePressed,
                      child: const Text('Done'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
