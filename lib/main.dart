import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'study_set.dart';
import 'services/stt_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
//import 'sets_screen.dart';

//final GlobalKey<SetsScreenState> setsScreenKey = GlobalKey<SetsScreenState>();

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
      title: 'Audio Study App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 132, 255),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            // color: Color.fromRGBO(255, 194, 10, 10),
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(12, 123, 220, 10),
          ),
          bodyMedium: GoogleFonts.poppins(),
          displaySmall: GoogleFonts.poppins(color: Colors.black, fontSize: 24),
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
  final VoidCallback onCreateSetButtonPressed;
  final void Function(StudySet newSet) onAddSet;

  const HomeScreen({
    super.key,
    required this.onCreateSetButtonPressed,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(12, 123, 220, 10),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Text(
                "Hello!",
                style: GoogleFonts.poppins(
                  textStyle: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              SizedBox(width: 10, height: 10),
              Text(
                "Welcome to Audio Study App",
                style: GoogleFonts.poppins(
                  textStyle: Theme.of(context).textTheme.titleLarge,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(width: 40, height: 40),
              Divider(
                // Horizontal line separator
                color: const Color.fromRGBO(255, 194, 10, 10),
                thickness: 3, // Line thickness
                indent: 16, // Space at the start of the line
                endIndent: 16, // Space at the end of the line
              ),
              SizedBox(width: 40, height: 40),
              ElevatedButton(
                onPressed: onCreateSetButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(
                    255,
                    194,
                    10,
                    10,
                  ), // Background color
                  foregroundColor: Colors.white, // Text/icon color
                  shadowColor: Colors.black, // Shadow color
                  elevation: 10.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 60,
                  ),
                ),
                child: Text(
                  "Create New Set",
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  StudySet? nSet = await importCsvAndCreateSet();
                  if (nSet != null) {
                    onAddSet(nSet);
                  }
                  // setState(() {
                  //   setsScreenKey.currentState?.addSet(nSet!);
                  //   print(setsScreenKey.currentState?.sets.length);
                  //   BottomNavBarState? navBarState = context
                  //       .findAncestorStateOfType<BottomNavBarState>();
                  //   navBarState?.onIconPressed(1);
                  // });
                },
                child: Text("Import CSV"),
              ),
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
  int selectedIndex = 0;
  //final List<StudySet> finalSets = [];
  final List<StudySet> sets = [];
  int numberOfSets = 0;

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
          ),
          SetsScreen(sets: sets, onDelete: deleteSet),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onIconPressed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Sets"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
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
      backgroundColor: Color.fromRGBO(12, 123, 220, 10),
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Profile Screen',
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
    );
  }
}
