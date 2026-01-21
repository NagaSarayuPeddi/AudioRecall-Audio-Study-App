import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';

class Set {
  final String id;
  final String name;
  final String description;
  final List<FlashCard> flashCards;

  Set({
    required this.id,
    required this.name,
    required this.description,
    required this.flashCards,
  });
}

class SetWidget extends StatefulWidget {
  final Set set;

  const SetWidget({super.key, required this.set});

  @override
  State<SetWidget> createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  // void donePressed = () {
  //   set.id =
  // };

  TextEditingController? nameController;
  TextEditingController? descriptionController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.set.name);
    descriptionController = TextEditingController(text: widget.set.description);
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
                Text(
                  "Set Name: ",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
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
              controller: descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter description',
                labelText: 'Decription',
              ),
            ),
            // TextButton(onPressed: onPressed, child: Text('Done'))
          ],
        ),
      ),
    );
  }
}
