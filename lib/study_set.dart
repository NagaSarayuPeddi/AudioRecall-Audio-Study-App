import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'cards_page.dart';

class StudySet {
  final String id;
  String name;
  String description;
  List<FlashCard> flashCards;
  bool isEditing = true; // controls Done vs Trash

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
  final void Function(StudySet set)? onDelete;

  const SetWidget({super.key, required this.set, required this.onDelete});

  @override
  State<SetWidget> createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  TextEditingController? nameController;
  TextEditingController? descriptionController;

  void donePressed() {
    setState(() {
      widget.set.isEditing = false;
      widget.set.name = nameController!.text;
      widget.set.description = descriptionController!.text;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CardPage(cardSet: widget.set)),
    );
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.set.name);
    descriptionController = TextEditingController(text: widget.set.description);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (!widget.set.isEditing) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardPage(cardSet: widget.set),
            ),
          );
        }
      },
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Set Name: ",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      enabled: widget.set.isEditing,
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter set name',
                        labelText: 'Set Name',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                enabled: widget.set.isEditing,
                controller: descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                  labelText: 'Decription',
                ),
              ),
              const SizedBox(height: 10),
              if (widget.set.isEditing)
                TextButton(onPressed: donePressed, child: const Text('Done'))
              else
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    if (widget.onDelete != null) {
                      widget.onDelete?.call(
                        widget.set,
                      ); // notify parent to delete this set
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
