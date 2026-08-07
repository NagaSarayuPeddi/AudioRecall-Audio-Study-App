import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'widgets/study_set.dart';
import 'sets_screen.dart';
import 'services/ai_service.dart';
import 'services/tts_service.dart';
import 'services/stt_service.dart';
import 'main.dart' show importCsvAndCreateSet;
import 'main.dart' show BottomNavBarState;

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ── Logo ──────────────────────────────────────────
              Image.asset(
                'assets/images/echolearn.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              // ── Welcome ───────────────────────────────────────
              Text(
                'Welcome to AudioRecall',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Audio-first flashcard studying',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.white60),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // ── New user button ───────────────────────────────
              _OutlineButton(
                label: "I'm new — show me around",
                icon: Icons.help_outline,
                onTap: () {
                  final navBarState = context
                      .findAncestorStateOfType<BottomNavBarState>();
                  navBarState?.onIconPressed(3);
                },
              ),

              const SizedBox(height: 28),

              // ── Section label ─────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a study set',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Import CSV ────────────────────────────────────
              _ActionCard(
                icon: Icons.upload_file_outlined,
                title: 'Import CSV',
                subtitle: 'Upload a spreadsheet of words and definitions',
                onTap: () async {
                  final nSet = await importCsvAndCreateSet();
                  if (nSet != null) onAddSet(nSet);
                },
              ),

              const SizedBox(height: 12),

              // ── Generate with AI ──────────────────────────────
              _ActionCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Generate with AI',
                subtitle: 'Speak a topic and number of cards to create',
                onTap: () async {
                  await TTSSettings.tts.speak(
                    "What topic do you want to study?",
                  );
                  await Future.delayed(const Duration(milliseconds: 400));

                  final topic = await STTService().listenOnce();
                  if (topic.isEmpty) return;

                  await TTSSettings.tts.speak(
                    'How many flashcards do you want?',
                  );
                  await Future.delayed(const Duration(milliseconds: 400));

                  final num = await STTService().listenOnce();

                  await TTSSettings.tts.speak('Generating your set…');

                  final newSet = await AIService.generateStudySet(topic, num);
                  if (newSet != null) {
                    onAddSet(newSet);
                    await TTSSettings.tts.speak(
                      '${newSet.name} is ready with '
                      '${newSet.flashCards.length} cards.',
                    );
                  } else {
                    await TTSSettings.tts.speak(
                      'Sorry, generation failed. '
                      'Check your connection and try again.',
                    );
                  }
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable sub-widgets ────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDB366),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF364B9A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF364B9A), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF364B9A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF364B9A).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF364B9A),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white38),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// Make BottomNavBarState accessible from home_screen.dart
// (add this import in home_screen.dart): import 'main.dart' show BottomNavBarState;
