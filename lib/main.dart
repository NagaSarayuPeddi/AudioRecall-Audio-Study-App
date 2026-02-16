import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
import 'study_set.dart';
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
      title: 'Audio Study App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 132, 255),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 194, 10, 10),
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

class HomeScreen extends StatefulWidget {
  final VoidCallback onCreateSetButtonPressed;

  const HomeScreen({super.key, required this.onCreateSetButtonPressed});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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
                onPressed: widget.onCreateSetButtonPressed,
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
  final List<StudySet> finalSets = [];

  late List<Widget> widgetOptions = <Widget>[
    HomeScreen(onCreateSetButtonPressed: () => onIconPressed(1)),
    SetsScreen(sets: finalSets),
    ProfileScreen(),
  ];

  void onIconPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: Center(child: widgetOptions.elementAt(selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            backgroundColor: const Color.fromARGB(31, 255, 255, 255),
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Sets"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        currentIndex: selectedIndex,
        onTap: onIconPressed,
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

// class CreateSetScreen extends StatelessWidget {
//   const CreateSetScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Text(
//       'Create Set Screen',
//       style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//     );
//   }
// }

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
