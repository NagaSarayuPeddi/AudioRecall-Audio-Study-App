import 'package:flutter/material.dart';
import 'flash_card.dart';
import 'study_set.dart';
import 'study_session.dart';
import 'services/tts_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void initState() {
    super.initState();
    loadVoices();
  }

  Future<void> loadVoices() async {
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
      appBar: AppBar(title: Text("Settings"), centerTitle: true),
      body: Column(
        children: [
          DropdownButton<Map<String, String>>(
            hint: Text("Select Voice"),
            value: TTSSettings.selectedVoice,
            items: TTSSettings.voices.map((voice) {
              //final v = Map<String, String>.from(voice);
              return DropdownMenuItem(
                value: voice,
                child: Text(voice['name'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (voice) async {
              setState(() {
                TTSSettings.selectedVoice = voice;
              });

              await TTSSettings.tts.setVoice(voice!);

              await TTSSettings.tts.speak("Voice changed to ${voice['name']}");
            },
          ),
          Text("Speed"),
          Slider(
            value: TTSSettings.speechRate,
            min: 0.2,
            max: 2.0,
            divisions: 8,
            label: TTSSettings.speechRate.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                TTSSettings.speechRate = value;
              });
              TTSSettings.tts.setSpeechRate(TTSSettings.speechRate);
            },
          ),
        ],
      ),
    );
  }
}
