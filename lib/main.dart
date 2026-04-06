import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'study_set.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'profile_screen.dart';
import 'services/ai_service.dart';
import 'services/tts_service.dart';
import 'services/stt_service.dart';

void main() {
  //GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoLearn',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF364B9A), // navy background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF364B9A), // navy
          primary: const Color(0xFF364B9A), // navy
          secondary: const Color(0xFFFDB366), // orange
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white, // white on dark background
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFDB366), // orange
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFDB366), // orange
          ),
          bodyMedium: GoogleFonts.poppins(color: Colors.white),
          displaySmall: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDB366), // orange buttons
            foregroundColor: Colors.black, // text on buttons
          ),
        ),
      ),
      home: const BottomNavBar(),
    );
  }
}

// class HomeScreen extends StatefulWidget {
//   final VoidCallback onCreateSetButtonPressed;

//   const HomeScreen({super.key, required this.onCreateSetButtonPressed});

//   @override
//   State<HomeScreen> createState() => HomeScreenState();
// }

class HomeScreen extends StatelessWidget {
  final String userName;
  final VoidCallback onCreateSetButtonPressed;
  final void Function(StudySet newSet) onAddSet;

  const HomeScreen({
    super.key,
    required this.onCreateSetButtonPressed,
    required this.onAddSet,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Text(
                userName.isEmpty ? "Hello!" : "Hello, $userName!",
                style: GoogleFonts.poppins(
                  textStyle: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              SizedBox(width: 10, height: 10),
              Text(
                "Welcome to EchoLearn!",
                style: GoogleFonts.poppins(
                  textStyle: Theme.of(context).textTheme.titleLarge,
                ),
                textAlign: TextAlign.center,
              ),
              //SizedBox(width: 40, height: 40),
              SizedBox(height: 20), // optional spacing
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF364B9A), // navy background
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.headphones,
                    size: 80,
                    color: const Color(0xFFFDB366), // orange
                  ),
                ),
              ),
              SizedBox(height: 20), // spacing before divider
              Divider(
                color: const Color(0xFFFDB366), // orange
                thickness: 3,
                indent: 16,
                endIndent: 16,
              ),
              SizedBox(width: 40, height: 40),
              ElevatedButton(
                onPressed: () async {
                  StudySet? nSet = await importCsvAndCreateSet();
                  if (nSet != null) {
                    onAddSet(nSet);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDB366), // orange
                  foregroundColor: Colors.black, // more readable
                  shadowColor: Colors.black,
                  elevation: 10.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                ),
                child: Text(
                  "Import CSV",
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF364B9A),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  await TTSSettings.tts.speak(
                    "What's the topic you want to study?",
                  );
                  await Future.delayed(const Duration(milliseconds: 500));

                  String topic = await STTService().listenOnce();

                  await Future.delayed(const Duration(milliseconds: 500));

                  if (topic.isEmpty) return;

                  await TTSSettings.tts.speak(
                    "How many flashcards do you want in your set?",
                  );

                  await Future.delayed(const Duration(milliseconds: 500));

                  String num = await STTService().listenOnce();

                  await Future.delayed(const Duration(seconds: 2));

                  StudySet? newSet = await AIService.generateStudySet(
                    topic,
                    num,
                  );
                  if (newSet != null) {
                    onAddSet(newSet);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDB366), // orange
                  foregroundColor: Colors.black, // more readable
                  shadowColor: Colors.black,
                  elevation: 10.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                ),
                child: Text(
                  "Generate with AI",
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: const Color(0xFF364B9A)),
                  ),
                ),
              ),
              //   ElevatedButton(
              // onPressed: () async {
              //       StudySet? nSet = await importCsvAndCreateSet();
              //      if (nSet != null) {
              //        onAddSet(nSet);
              //     }
              // setState(() {
              //   setsScreenKey.currentState?.addSet(nSet!);
              //   print(setsScreenKey.currentState?.sets.length);
              //   BottomNavBarState? navBarState = context
              //       .findAncestorStateOfType<BottomNavBarState>();
              //   navBarState?.onIconPressed(1);
              // });
              //   },
              //          child: Text("Import CSV"),
              //       ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  String userName = "";
  int selectedIndex = 0;
  //final List<StudySet> finalSets = [];
  final List<StudySet> sets = [];
  int numberOfSets = 0;

  static List<StudySet> initialSets = [];

  @override
  void initState() {
    super.initState();
    initSets();
  }

  Future<void> initSets() async {
    await loadInitialSets();
    setState(() {
      for (StudySet set in initialSets) {
        addSet(set);
      }
    });
  }

  // late List<Widget> widgetOptions = <Widget>[
  //   HomeScreen(onCreateSetButtonPressed: () => onIconPressed(1)),
  //   SetsScreen(key: setsScreenKey),
  //   ProfileScreen(),
  // ];

  void onIconPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void addSet(StudySet newSet) {
    setState(() {
      numberOfSets++;
      newSet.id = numberOfSets.toString();
      sets.add(newSet);
      newSet.isEditing = false;
      selectedIndex = 1; // go to Sets screen
      print("Added set: ${newSet.name}");
    });
  }

  void deleteSet(StudySet setToDelete) {
    setState(() {
      sets.remove(setToDelete);
      print("Deleted set: ${setToDelete.name}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      // body: Center(child: widgetOptions.elementAt(selectedIndex)),
      // bottomNavigationBar: BottomNavigationBar(
      //   items: <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: "Home",
      //       backgroundColor: const Color.fromARGB(31, 255, 255, 255),
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.book), label: "Sets"),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      //   ],
      //   currentIndex: selectedIndex,
      //   onTap: onIconPressed,
      // ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeScreen(
            onCreateSetButtonPressed: () => onIconPressed(1),
            onAddSet: addSet,
            userName: userName,
          ),
          SetsScreen(sets: sets, onDelete: deleteSet),
          ProfileScreen(
            onNameChanged: (name) {
              setState(() {
                userName = name;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onIconPressed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Sets"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

// Sample data: multiple FlashCard instances
// final List<FlashCard> sampleCards = [
//   FlashCard(
//     id: '1',
//     question: 'What is Flutter?',
//     answer: 'A UI toolkit by Google',
//   ),
//   FlashCard(id: '2', question: 'What language is used?', answer: 'Dart'),
//   FlashCard(
//     id: '3',
//     question: 'Stateful or Stateless?',
//     answer: 'Both, depending on widget',
//   ),
// ];

// final List<Set> sampleSets = [
//   Set(
//     id: '1',
//     name: 'Vocabulary',
//     description: 'Biology terms',
//     flashCards: sampleCards,
//   ),
// ];

// class SetsScreen extends StatefulWidget {
//   final List<StudySet> sets;

//   const SetsScreen({super.key, required this.sets});

//   @override
//   State<SetsScreen> createState() => SetsScreenState();
// }

// class SetsScreenState extends State<SetsScreen> {
//   // int numberOfSets = 0;
//   // List<StudySet> sets = [];

//   // void addSet(StudySet newSet) {
//   //   setState(() {
//   //     numberOfSets++;
//   //     newSet.id = numberOfSets.toString();
//   //     sets.add(newSet);
//   //     print("Added set: ${newSet.name} with id ${newSet.id}");
//   //   });
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color.fromRGBO(12, 123, 220, 10),
//       appBar: AppBar(title: const Text('Sets')),
//       body: Column(
//         children: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: () {
//               StudySet nSet = StudySet(
//                 id: numberOfSets.toString(),
//                 name: '',
//                 description: '',
//                 flashCards: new List<FlashCard>.empty(growable: true),
//               );
//               addSet(nSet);
//             },
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: sets.length,
//               itemBuilder: (context, index) {
//                 return SetWidget(
//                   key: ValueKey(sets[index].id),
//                   set: sets[index],
//                   onDelete: (setToDelete) {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext dialogContext) {
//                         return AlertDialog(
//                           content: const Text(
//                             'Are you sure you want to delete this set?',
//                             style: TextStyle(fontSize: 20),
//                             textAlign: TextAlign.center,
//                           ),

//                           actions: [
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.pop(dialogContext);
//                               },
//                               child: const Text('Cancel'),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   sets.removeWhere(
//                                     (set_) => set_.id == setToDelete.id,
//                                   );
//                                 });
//                                 Navigator.pop(dialogContext);
//                               },
//                               child: const Text(
//                                 'Delete',
//                                 style: TextStyle(color: Colors.red),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class SetsScreen extends StatelessWidget {
  final List<StudySet> sets;
  final void Function(StudySet setToDelete) onDelete;
  const SetsScreen({super.key, required this.sets, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      appBar: AppBar(title: const Text('Sets')),
      body: ListView.builder(
        itemCount: sets.length,
        itemBuilder: (context, index) {
          return SetWidget(
            key: ValueKey(sets[index].id),
            set: sets[index],
            onDelete: (setToDelete) {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    content: const Text(
                      'Are you sure you want to delete this set?',
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
                          //sets.removeWhere((set_) => set_.id == setToDelete.id);
                          // sets.remove(setToDelete);
                          // print("Set deleted: ${setToDelete.name}");
                          onDelete(setToDelete);
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
    );
  }
}

Future<void> loadInitialSets() async {
  List<String> paths = [
    "assets/data/computer_science.csv",
    "assets/data/economics.csv",
    "assets/data/geography.csv",
    "assets/data/psychology_terms.csv",
    "assets/data/sat_vocab.csv",
  ];
  List<String> setNames = [
    "Computer Science",
    "Economics",
    "Geography",
    "Psychology",
    "SAT Vocabulary",
  ];

  for (int i = 0; i < paths.length; i++) {
    StudySet iset = await loadCsvAsStudySet(paths[i], setNames[i]);
    BottomNavBarState.initialSets.add(iset);
  }
}

Future<StudySet> loadCsvAsStudySet(String path, String setName) async {
  final raw = await rootBundle.loadString(path);

  final cleaned = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  print("RAW CSV:\n$cleaned"); // DEBUG

  final csvTable = const CsvToListConverter(eol: '\n').convert(cleaned);

  print("Parsed rows: ${csvTable.length}");

  List<FlashCard> cards = [];

  for (int i = 1; i < csvTable.length; i++) {
    if (csvTable[i].length < 2) continue;

    print("Loaded card: ${csvTable[i][0]} - ${csvTable[i][1]}");

    cards.add(
      FlashCard(
        id: i.toString(),
        question: csvTable[i][0].toString(),
        answer: csvTable[i][1].toString(),
        isEditing: false,
      ),
    );
  }

  return StudySet(id: "", description: "", name: setName, flashCards: cards);
}

Future<StudySet?> importCsvAndCreateSet() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result == null) {
    print("No file selected");
    return null;
  }

  final bytes = result.files.single.bytes;
  if (bytes == null) {
    print("Failed to read file bytes");
    return null;
  }

  String csvString = utf8.decode(bytes);

  List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

  if (csvTable.length <= 1) return null; // no data

  String setName = result.files.single.name.replaceAll(".csv", "");

  List<FlashCard> cards = [];

  //_SetsScreenState().numberOfSets++;

  for (int i = 1; i < csvTable.length; i++) {
    String word = csvTable[i][0].toString();
    String definition = csvTable[i][1].toString();

    cards.add(
      FlashCard(
        id: i.toString(),
        question: word,
        answer: definition,
        isEditing: false,
      ),
    );
    print("Added card: $word - $definition");
  }

  return StudySet(id: "", description: "", name: setName, flashCards: cards);
}

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Settings"), centerTitle: true),
//         body: Column(
//           children: [
//             DropdownButton<Map<String, String>>(
//               hint: Text("Select Voice"),
//               value: selectedVoice,
//               items: voices.map((voice) {
//                 final v = Map<String, String>.from(voice);
//                 return DropdownMenuItem(value: v, child: Text("${v['name']}"));
//               }).toList(),
//               onChanged: (voice) async {
//                 setState(() {
//                   selectedVoice = voice;
//                 });

//                 await tts.setVoice(voice!);

//                 await tts.speak("Voice changed to ${voice['name']}");
//               },
//             ),
//             Text("Speed"),
//             Slider(
//               value: speechRate,
//               min: 0.2,
//               max: 2.0,
//               divisions: 8,
//               label: speechRate.toStringAsFixed(2),
//               onChanged: (value) {
//                 setState(() {
//                   speechRate = value;
//                 });
//                 tts.setSpeechRate(speechRate);
//               },
//             ),
//             Center(
//               child: ElevatedButton(
//                 child: Text(isSessionActive ? 'End Session' : 'Start Session'),
//                 onPressed: () {
//                   if (isSessionActive) {
//                     endSession();
//                     tts.speak('Study session ended. Great job!');
//                   } else {
//                     startSession();
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
