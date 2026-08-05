import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/tts_service.dart';

String userName = '';

class ProfileScreen extends StatefulWidget {
  final Function(String) onNameChanged;
  const ProfileScreen({super.key, required this.onNameChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    await TTSSettings.loadVoices();
    if (TTSSettings.voices.isNotEmpty) {
      TTSSettings.selectedVoice = TTSSettings.voices.first;
      await TTSSettings.tts.setVoice(TTSSettings.selectedVoice!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF364B9A),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Voice section ──────────────────────────────────
              _SectionLabel('Voice'),
              const SizedBox(height: 8),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speaker voice',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // full-width, fontSize 16 so names don't overflow
                    DropdownButtonFormField<Map<String, String>>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        // ignore: deprecated_member_use
                        fillColor: Colors.white.withOpacity(0.08),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF364B9A),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      hint: Text(
                        'Select a voice',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white54,
                        ),
                      ),
                      initialValue: TTSSettings.selectedVoice,
                      items: TTSSettings.voices.map((voice) {
                        return DropdownMenuItem(
                          value: voice,
                          child: Text(
                            voice['name'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (voice) async {
                        if (voice == null) return;
                        setState(() => TTSSettings.selectedVoice = voice);
                        await TTSSettings.tts.setVoice(voice);
                        await TTSSettings.tts.speak(
                          'Voice changed to ${voice['name']}',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Speed section ──────────────────────────────────
              _SectionLabel('Speed'),
              const SizedBox(height: 8),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Speech rate',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: const Color(0xFFFDB366).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${TTSSettings.speechRate.toStringAsFixed(1)}×',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFDB366),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFFDB366),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFFFDB366),
                        overlayColor:
                            // ignore: deprecated_member_use
                            const Color(0xFFFDB366).withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: TTSSettings.speechRate,
                        min: 0.2,
                        max: 2.0,
                        divisions: 18,
                        onChanged: (value) {
                          TTSSettings.tts.stop();
                          setState(() => TTSSettings.speechRate = value);
                          TTSSettings.tts.setSpeechRate(value);
                        },
                        onChangeEnd: (value) async {
                          await TTSSettings.tts.speak(
                            'Speed set to ${value.toStringAsFixed(1)}',
                          );
                        },
                      ),
                    ),
                    // Speed labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Slow',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                          Text(
                            'Fast',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}
