import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'cards_page.dart';
import 'services/stt_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StudySet {
  String id;
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
  // final void Function(StudySet set)? onDelete;
  final void Function(StudySet set) onDelete;

  const SetWidget({super.key, required this.set, required this.onDelete});

  @override
  State<SetWidget> createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  TextEditingController? nameController;
  TextEditingController? descriptionController;

  final stt = STTService();
  bool isListeningDescription = false;
  bool isListeningName = false;

  final FlutterTts tts = FlutterTts();

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

    stt.initialize();
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
        color: Color.fromRGBO(255, 194, 10, 10),
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  if (widget.set.isEditing) {
                    return Row(
                      children: [
                        Text(
                          "Set Name: ",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(width: 10),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter set name',
                            labelText: 'Set Name',
                          ),
                        ),
                        // Expanded(
                        //   child: Builder(
                        //     builder: (context) {
                        //       if (widget.set.isEditing) {
                        //         return TextField(
                        //           controller: nameController,
                        //           decoration: const InputDecoration(
                        //             border: OutlineInputBorder(),
                        //             hintText: 'Enter set name',
                        //             labelText: 'Set Name',
                        //           ),
                        //         );
                        //       } else {
                        //         return Text(
                        //           widget.set.name,
                        //           style: Theme.of(context).textTheme.titleLarge,
                        //         );
                        //       }
                        //     },
                        //   ),
                        // ),
                        // Builder(
                        //   builder: (context) {
                        //     if (widget.set.isEditing) {
                        //       return
                        GestureDetector(
                          onTap: () async {
                            if (!isListeningName) {
                              // Initialize speech-to-text first
                              // bool available = await stt.initialize();
                              // if (!available) {
                              //   print(
                              //     "Microphone not available or permission denied",
                              //   );
                              //   return;
                              // }
                              await tts.speak(
                                "Microphone activated. Start speaking the set name.",
                              );
                              // Start listening
                              setState(() => isListeningName = true);
                              await stt.listen(
                                onResult: (text) {
                                  setState(() {
                                    nameController!.text = text;
                                  });
                                },
                              );
                            } else {
                              // Stop listening
                              await tts.speak("Microphone deactivated.");
                              stt.stopListening();
                              setState(() => isListeningName = false);
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
                              isListeningName ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          // child: IconButton(
                          //   icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                          // onPressed: () async {
                          //   if (!isListening) {
                          //     // Initialize speech-to-text first
                          //     bool available = await stt.initialize();
                          //     if (!available) {
                          //       print(
                          //         "Microphone not available or permission denied",
                          //       );
                          //       return;
                          //     }

                          //     // Start listening
                          //     setState(() => isListening = true);
                          //     stt.startListening((text) {
                          //       setState(() {
                          //         nameController!.text = text;
                          //       });
                          //     });
                          //   } else {
                          //     // Stop listening
                          //     stt.stopListening();
                          //     setState(() => isListening = false);
                          //   }
                          // },
                          //),
                        ),
                        // } else {
                        //   return const SizedBox.shrink();
                        // }
                        //   },
                        // ),
                      ],
                    );
                  } else {
                    // return Text(
                    //   widget.set.name,
                    //   style: Theme.of(context).textTheme.titleLarge,
                    //   );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.set.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            widget.onDelete(widget.set);
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (widget.set.isEditing) {
                          return TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter description',
                              labelText: 'Description',
                            ),
                          );
                        } else {
                          // return Text(
                          //   widget.set.description,
                          //   style: Theme.of(context).textTheme.displaySmall,
                          // );
                          return SizedBox(width: 0, height: 0);
                        }
                      },
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      if (widget.set.isEditing) {
                        return GestureDetector(
                          onTap: () async {
                            if (!isListeningDescription) {
                              // Initialize speech-to-text first
                              bool available = await stt.initialize();
                              if (!available) {
                                print(
                                  "Microphone not available or permission denied",
                                );
                                return;
                              }

                              await tts.speak(
                                "Microphone activated. Start speaking the description.",
                              );

                              // Start listening
                              setState(() => isListeningDescription = true);
                              await stt.listen(
                                onResult: (text) {
                                  setState(() {
                                    descriptionController!.text = text;
                                  });
                                },
                              );
                            } else {
                              await tts.speak("Microphone deactivated.");
                              // Stop listening
                              stt.stopListening();
                              setState(() => isListeningDescription = false);
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
                              isListeningDescription
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (widget.set.isEditing)
                    TextButton(
                      onPressed: donePressed,
                      child: const Text('Done'),
                    )
                  else
                    const SizedBox(),

                  Spacer(), // pushes delete to the right

                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      iconSize: 30,
                      onPressed: () {
                        if (widget.onDelete != null) {
                          widget.onDelete?.call(widget.set);
                        }
                      },
                    ),
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
