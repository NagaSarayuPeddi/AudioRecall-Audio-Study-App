import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'cards_page.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'widgets/accessible_mic_button.dart';

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
    required this.isEditing,
  });
}

// ─── Sets screen ──────────────────────────────────────────────────────────────

class SetsScreen extends StatelessWidget {
  final List<StudySet> sets;
  final void Function(StudySet setToDelete) onDelete;

  const SetsScreen({super.key, required this.sets, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF364B9A),
        foregroundColor: Colors.white,
        title: const Text('My sets'),
        centerTitle: true,
      ),
      body: sets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.style_outlined,
                    size: 56,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No sets yet',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Import a CSV or generate one with AI\non the Home tab',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: sets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return SetWidget(
                  key: ValueKey(sets[index].id),
                  set: sets[index],
                  onDelete: (setToDelete) =>
                      _confirmDelete(context, setToDelete, onDelete),
                );
              },
            ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    StudySet setToDelete,
    void Function(StudySet) onDelete,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete set?'),
        content: Text(
          'This will permanently remove "${setToDelete.name}" '
          'and all its cards.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete(setToDelete);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Set widget ───────────────────────────────────────────────────────────────

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

  final _stt = STTService();
  bool _listeningName = false;
  bool _listeningDesc = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.set.name);
    descriptionController = TextEditingController(text: widget.set.description);
    _stt.initialize();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _done() {
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
    if (!_listeningName) {
      await TTSSettings.tts.speak('Speak the set name.');
      setState(() => _listeningName = true);
      await _stt.listen(
        onResult: (t) => setState(() => nameController.text = t),
      );
    } else {
      await _stt.stopListening();
      setState(() => _listeningName = false);
    }
  }

  Future<void> _toggleDescMic() async {
    if (!_listeningDesc) {
      final ok = await _stt.initialize();
      if (!ok) return;
      await TTSSettings.tts.speak('Speak the description.');
      setState(() => _listeningDesc = true);
      await _stt.listen(
        onResult: (t) => setState(() => descriptionController.text = t),
      );
    } else {
      await _stt.stopListening();
      setState(() => _listeningDesc = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.set.isEditing ? _buildEditing() : _buildDisplay();
  }

  // ── Editing state ─────────────────────────────────────────────────────────

  Widget _buildEditing() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDB366),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          Text(
            'Set name',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF364B9A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(
                    color: Color(0xFF364B9A),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Biology Chapter 3',
                    hintStyle: TextStyle(
                      color: const Color(0xFF364B9A),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AccessibleMicButton(
                isListening: _listeningName,
                fieldLabel: 'set name',
                onTap: _toggleNameMic,
                size: 44,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description field
          Text(
            'Description (optional)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF364B9A).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: descriptionController,
                  style: const TextStyle(
                    color: Color(0xFF364B9A),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Vocabulary for midterm',
                    hintStyle: TextStyle(
                      color: const Color(0xFF364B9A),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AccessibleMicButton(
                isListening: _listeningDesc,
                fieldLabel: 'description',
                onTap: _toggleDescMic,
                size: 44,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _done,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF364B9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Display state ─────────────────────────────────────────────────────────

  Widget _buildDisplay() {
    final cardCount = widget.set.flashCards.length;

    return Semantics(
      label: '${widget.set.name}, $cardCount cards. Double tap to open.',
      button: true,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardPage(cardSet: widget.set)),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDB366),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left: icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF364B9A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  //Icons.school_outlined,
                  Icons.style_outlined,
                  color: Color(0xFFFDB366),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Middle: name + card count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.set.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF364B9A),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cardCount ${cardCount == 1 ? 'card' : 'cards'}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF364B9A),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: delete + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Edit ${widget.set.name}',
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF364B9A),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => widget.set.isEditing = true),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Delete ${widget.set.name}',
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => widget.onDelete(widget.set),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF364B9A),
                    size: 20,
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
