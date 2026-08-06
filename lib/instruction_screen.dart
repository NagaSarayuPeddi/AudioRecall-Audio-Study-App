import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/tts_service.dart';

class InstructionScreen extends StatelessWidget {
  final VoidCallback onImportCsv;
  final VoidCallback onGenerateAI;

  const InstructionScreen({
    super.key,
    required this.onImportCsv,
    required this.onGenerateAI,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF364B9A),
        foregroundColor: Colors.white,
        title: const Text('About EchoLearn'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero ────────────────────────────────────────────
              _HeroCard(),

              const SizedBox(height: 24),

              // ── How it works ────────────────────────────────────
              _SectionHeader('How it works'),
              const SizedBox(height: 12),
              _StepCard(
                number: '1',
                icon: Icons.add_circle_outline,
                title: 'Add a study set',
                body:
                    'Go to the Home tab and either import a CSV file '
                    'or say a topic and number of cards to generate a set '
                    'with AI. You can also create a set manually on the '
                    'Sets tab.',
              ),
              const SizedBox(height: 10),
              _StepCard(
                number: '2',
                icon: Icons.headphones_outlined,
                title: 'Start a study session',
                body:
                    'Open any set, tap "Study". The app reads each '
                    'definition aloud, then listens for you to say the '
                    'matching word. No screen needed — it works entirely '
                    'by voice.',
              ),
              const SizedBox(height: 10),
              _StepCard(
                number: '3',
                icon: Icons.bar_chart_outlined,
                title: 'Track your progress',
                body:
                    'After studying, tap the chart icon on any set to '
                    'see which cards you have mastered, which are familiar, '
                    'and which still need work. Your progress is saved '
                    'between sessions.',
              ),

              const SizedBox(height: 24),

              // ── During a session ────────────────────────────────
              _SectionHeader('During a session'),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.mic_outlined,
                title: 'Just speak your answer',
                body:
                    'After the definition is read, say the word aloud. '
                    'You have 8 seconds. The app understands natural '
                    'speech — "the supply" or "supplies" will both match '
                    '"supply".',
              ),
              const SizedBox(height: 10),
              _InfoCard(
                icon: Icons.touch_app_outlined,
                title: 'Tap and double-tap gestures',
                body:
                    'If you are unsure of an answer, say nothing and '
                    'the app will ask if you need help.\n\n'
                    '• Single tap — reveal the correct answer and move on\n'
                    '• Double tap — try the same card again',
              ),
              const SizedBox(height: 10),
              _InfoCard(
                icon: Icons.stop_circle_outlined,
                title: 'Stop at any time',
                body:
                    'Say "stop" at any point to end the session early. '
                    'You will hear a summary of your score.',
              ),
              const SizedBox(height: 10),
              _InfoCard(
                icon: Icons.sentiment_dissatisfied_outlined,
                title: 'Don\'t know an answer?',
                body:
                    'Say "I don\'t know" and the app will ask if you '
                    'want to hear the correct answer. Saying yes reveals '
                    'it and moves on without counting against your score '
                    'if you have already used an attempt.',
              ),

              const SizedBox(height: 24),

              // ── Mastery levels ──────────────────────────────────
              _SectionHeader('Mastery levels'),
              const SizedBox(height: 12),
              _MasteryCard(
                emoji: '⭐',
                label: 'Mastered',
                color: Colors.amber,
                body:
                    '90% or higher accuracy and answered correctly '
                    'at least 3 times. This card is solid.',
              ),
              const SizedBox(height: 10),
              _MasteryCard(
                emoji: '✅',
                label: 'Familiar',
                color: Colors.green,
                body:
                    '70–89% accuracy. You know this card well '
                    'but a little more practice will lock it in.',
              ),
              const SizedBox(height: 10),
              _MasteryCard(
                emoji: '🔁',
                label: 'Needs work',
                color: Colors.red,
                body:
                    'Below 70% accuracy. Focus on these cards '
                    'in your next session to bring them up.',
              ),

              const SizedBox(height: 24),

              // ── CSV format ──────────────────────────────────────
              _SectionHeader('Importing a CSV'),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.table_chart_outlined,
                title: 'Format',
                body:
                    'Your CSV file should have two columns: '
                    'Word and Definition. The first row should be '
                    'a header row.\n\n'
                    'Word,Definition\n'
                    'Mitosis,Cell division process\n'
                    'Osmosis,Movement of water through a membrane',
              ),

              const SizedBox(height: 24),

              // ── Settings tips ───────────────────────────────────
              _SectionHeader('Tips'),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.speed_outlined,
                title: 'Adjust the speed',
                body:
                    'Go to Settings (bottom tab) to change the voice '
                    'and reading speed. Slower speeds help when first '
                    'learning a set.',
              ),
              const SizedBox(height: 10),
              _InfoCard(
                icon: Icons.wifi_off_outlined,
                title: 'AI generation needs internet',
                body:
                    'Generating sets with AI requires a network '
                    'connection. Studying, importing CSVs, and viewing '
                    'progress all work offline.',
              ),

              const SizedBox(height: 24),

              // ── About ───────────────────────────────────────────
              _SectionHeader('About'),
              const SizedBox(height: 12),
              _AboutCard(),

              const SizedBox(height: 16),

              // ── Read aloud button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _readPageAloud(),
                  icon: const Icon(Icons.volume_up_outlined, size: 18),
                  label: const Text('Read this page aloud'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _readPageAloud() async {
    await TTSSettings.tts.speak(
      'Welcome to EchoLearn. '
      'EchoLearn is an audio-first flashcard app designed for students '
      'with visual impairments. '
      'Here is how to use it. '
      'Step 1: Add a study set. Go to the Home tab and import a CSV '
      'or generate a set with AI by saying a topic. '
      'Step 2: Start a study session. Open any set and tap Study. '
      'The app reads each definition aloud and listens for your answer. '
      'Step 3: Track your progress. Tap the chart icon to see mastery. '
      'During a session, say your answer after the definition is read. '
      'Single tap to reveal an answer. Double tap to try again. '
      'Say stop to end the session. '
      'Say I don\'t know to skip a card. '
      'Mastery levels: Mastered means 90 percent or higher. '
      'Familiar means 70 to 89 percent. '
      'Needs work means below 70 percent.',
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDB366),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.headphones, size: 44, color: Color(0xFF364B9A)),
          const SizedBox(height: 12),
          Text(
            'EchoLearn',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF364B9A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Audio-first flashcard studying for everyone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF364B9A).withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFDB366),
        letterSpacing: 1.0,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String body;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFDB366),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF364B9A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFDB366), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final String body;

  const _MasteryCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EchoLearn was built to make studying accessible for '
            'students with visual impairments. It uses speech recognition '
            'and text-to-speech so the entire study flow — creating sets, '
            'studying cards, and reviewing progress — can be done '
            'completely by voice.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
