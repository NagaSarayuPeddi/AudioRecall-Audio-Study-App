import 'package:assisted_learning/home_screen.dart';
import 'package:assisted_learning/sets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flash_card.dart';
//import 'widgets/study_set.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'profile_screen.dart';
import 'instruction_screen.dart';
import 'services/ai_service.dart';
import 'services/tts_service.dart';
import 'services/stt_service.dart';
import 'services/app_config.dart'; // NEW
import 'services/persistence_service.dart'; // NEW

void main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress the mouse tracker assertion on macOS desktop
  // This is a known Flutter issue when hovering over widgets during navigation
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.toString().contains('mouse_tracker')) return;
    FlutterError.presentError(details);
  };

  // Load .env so AppConfig.cohereApiKey is available throughout the app
  await AppConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoLearn',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF364B9A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF364B9A),
          primary: const Color(0xFF364B9A),
          secondary: const Color(0xFFFDB366),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFDB366),
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFDB366),
          ),
          bodyMedium: GoogleFonts.poppins(color: Colors.white),
          displaySmall: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDB366),
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: const BottomNavBar(),
    );
  }
}

// ─── Home screen ────────────────────────────────────────────────────────────

// class HomeScreen extends StatelessWidget {
//   final String userName;
//   final VoidCallback onCreateSetButtonPressed;
//   final void Function(StudySet newSet) onAddSet;

//   const HomeScreen({
//     super.key,
//     required this.onCreateSetButtonPressed,
//     required this.onAddSet,
//     required this.userName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF364B9A),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Center(
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Text(
//                 'Welcome to EchoLearn!',
//                 style: GoogleFonts.poppins(
//                   textStyle: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 width: 300,
//                 height: 120,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF364B9A),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Image.asset(
//                   'assets/images/echolearn.png',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   final navBarState = context
//                       .findAncestorStateOfType<BottomNavBarState>();
//                   navBarState?.onIconPressed(3);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFFDB366),
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 30,
//                     vertical: 17,
//                   ),
//                 ),
//                 child: Text(
//                   "I'm new",
//                   style: GoogleFonts.poppins(
//                     textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
//                       color: const Color(0xFF364B9A),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Divider(
//                 color: const Color(0xFFFDB366),
//                 thickness: 3,
//                 indent: 16,
//                 endIndent: 16,
//               ),
//               const SizedBox(height: 40),
//               ElevatedButton(
//                 onPressed: () async {
//                   final nSet = await importCsvAndCreateSet();
//                   if (nSet != null) onAddSet(nSet);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFFDB366),
//                   foregroundColor: Colors.black,
//                   shadowColor: Colors.black,
//                   elevation: 10.0,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 30,
//                     vertical: 30,
//                   ),
//                 ),
//                 child: Text(
//                   'Import CSV',
//                   style: GoogleFonts.poppins(
//                     textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
//                       color: const Color(0xFF364B9A),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   await TTSSettings.tts.speak(
//                     "What's the topic you want to study?",
//                   );
//                   await Future.delayed(const Duration(milliseconds: 500));

//                   final topic = await STTService().listenOnce();
//                   if (topic.isEmpty) return;

//                   await TTSSettings.tts.speak(
//                     'How many flashcards do you want in your set?',
//                   );
//                   await Future.delayed(const Duration(milliseconds: 500));

//                   final num = await STTService().listenOnce();

//                   // Tell user we're loading — important for audio-first UX
//                   await TTSSettings.tts.speak('Loading your set. Please wait.');

//                   final newSet = await AIService.generateStudySet(topic, num);
//                   if (newSet != null) {
//                     onAddSet(newSet);
//                     await TTSSettings.tts.speak(
//                       'Your ${newSet.name} set is ready with '
//                       '${newSet.flashCards.length} cards.',
//                     );
//                   } else {
//                     // Give audio feedback on failure
//                     await TTSSettings.tts.speak(
//                       'Sorry, I could not generate the set. '
//                       'Please check your internet connection and try again.',
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFFDB366),
//                   foregroundColor: Colors.black,
//                   shadowColor: Colors.black,
//                   elevation: 10.0,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 30,
//                     vertical: 30,
//                   ),
//                 ),
//                 child: Text(
//                   'Generate with AI',
//                   style: GoogleFonts.poppins(
//                     textStyle: Theme.of(context).textTheme.titleMedium
//                         ?.copyWith(color: const Color(0xFF364B9A)),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ─── Bottom nav shell ────────────────────────────────────────────────────────

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  String userName = '';
  int selectedIndex = 0;
  final List<StudySet> sets = [];
  int _nextId = 1;

  // Tracks whether we've finished loading from disk
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSets();
  }

  /// Load persisted user sets, then append the built-in CSV sets.
  Future<void> _loadAllSets() async {
    // 1. Load whatever the user previously saved
    final saved = await PersistenceService.loadSets();

    // 2. Load the bundled CSV sets (always available, not editable by user)
    final builtin = await _loadBuiltinSets();

    if (!mounted) return;
    setState(() {
      sets.addAll(saved);
      sets.addAll(builtin);

      // Ensure _nextId is always higher than any existing id
      for (final s in sets) {
        final parsed = int.tryParse(s.id) ?? 0;
        if (parsed >= _nextId) _nextId = parsed + 1;
      }

      _isLoading = false;
    });
  }

  void onIconPressed(int index) => setState(() => selectedIndex = index);

  void addSet(StudySet newSet) {
    setState(() {
      newSet.id = (_nextId++).toString();
      newSet.isEditing = false;
      sets.insert(0, newSet); // newest first
      selectedIndex = 1;
    });
    // Persist only user-created sets (not the built-in CSV ones)
    _saveUserSets();
  }

  void deleteSet(StudySet setToDelete) {
    setState(() => sets.removeWhere((s) => s.id == setToDelete.id));
    _saveUserSets();
  }

  /// Save only the non-builtin sets (those created/imported by the user).
  Future<void> _saveUserSets() async {
    final builtinNames = {
      'Computer Science',
      'Economics',
      'Geography',
      'Psychology',
      'SAT Vocabulary',
    };
    final userSets = sets.where((s) => !builtinNames.contains(s.name)).toList();
    await PersistenceService.saveSets(userSets);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF364B9A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFDB366)),
        ),
      );
    }

    return Scaffold(
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
            onNameChanged: (name) => setState(() => userName = name),
          ),
          InstructionScreen(onImportCsv: () {}, onGenerateAI: () {}),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onIconPressed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF364B9A),
        unselectedItemColor: const Color.fromARGB(179, 118, 115, 115),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Sets'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Info'),
        ],
      ),
    );
  }
}

// ─── Sets screen ─────────────────────────────────────────────────────────────

// class SetsScreen extends StatelessWidget {
//   final List<StudySet> sets;
//   final void Function(StudySet setToDelete) onDelete;

//   const SetsScreen({super.key, required this.sets, required this.onDelete});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF364B9A),
//       appBar: AppBar(title: const Text('Sets')),
//       body: sets.isEmpty
//           ? Center(
//               child: Text(
//                 'No sets yet.\nImport a CSV or generate one with AI!',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
//               ),
//             )
//           : ListView.builder(
//               itemCount: sets.length,
//               itemBuilder: (context, index) {
//                 return SetWidget(
//                   key: ValueKey(sets[index].id),
//                   set: sets[index],
//                   onDelete: (setToDelete) {
//                     showDialog(
//                       context: context,
//                       builder: (dialogContext) => AlertDialog(
//                         content: const Text(
//                           'Are you sure you want to delete this set?',
//                           style: TextStyle(fontSize: 20, color: Colors.black),
//                           textAlign: TextAlign.center,
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(dialogContext),
//                             child: const Text('Cancel'),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               onDelete(setToDelete);
//                               Navigator.pop(dialogContext);
//                             },
//                             child: const Text(
//                               'Delete',
//                               style: TextStyle(color: Colors.red),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }

// ─── Built-in CSV loader ──────────────────────────────────────────────────────

Future<List<StudySet>> _loadBuiltinSets() async {
  const paths = [
    'assets/data/computer_science.csv',
    'assets/data/economics.csv',
    'assets/data/geography.csv',
    'assets/data/psychology_terms.csv',
    'assets/data/sat_vocab.csv',
  ];
  const names = [
    'Computer Science',
    'Economics',
    'Geography',
    'Psychology',
    'SAT Vocabulary',
  ];

  final result = <StudySet>[];
  for (var i = 0; i < paths.length; i++) {
    result.add(await _loadCsvAsStudySet(paths[i], names[i]));
  }
  return result;
}

Future<StudySet> _loadCsvAsStudySet(String path, String setName) async {
  final raw = await rootBundle.loadString(path);
  final cleaned = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final csvTable = const CsvToListConverter(eol: '\n').convert(cleaned);

  final cards = <FlashCard>[];
  for (var i = 1; i < csvTable.length; i++) {
    if (csvTable[i].length < 2) continue;
    cards.add(
      FlashCard(
        id: i.toString(),
        question: csvTable[i][0].toString(),
        answer: csvTable[i][1].toString(),
        isEditing: false,
      ),
    );
  }

  return StudySet(
    id: 'builtin_$setName',
    description: '',
    name: setName,
    flashCards: cards,
    isEditing: false,
  );
}

// ─── CSV importer ─────────────────────────────────────────────────────────────

Future<StudySet?> importCsvAndCreateSet() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (result == null) return null;

  final bytes = result.files.single.bytes;
  if (bytes == null) return null;

  final csvString = utf8.decode(bytes);
  final csvTable = const CsvToListConverter().convert(csvString);
  if (csvTable.length <= 1) return null;

  final setName = result.files.single.name.replaceAll('.csv', '');
  final cards = <FlashCard>[];

  for (var i = 1; i < csvTable.length; i++) {
    if (csvTable[i].length < 2) continue;
    cards.add(
      FlashCard(
        id: i.toString(),
        question: csvTable[i][0].toString(),
        answer: csvTable[i][1].toString(),
        isEditing: false,
      ),
    );
  }

  return StudySet(
    id: '',
    description: '',
    name: setName,
    flashCards: cards,
    isEditing: false,
  );
}
