import 'package:flutter/material.dart';
import 'flash_card.dart';
import 'study_set.dart';
import 'study_session.dart';
import 'services/tts_service.dart';

String userName = "";

class ProfileScreen extends StatefulWidget {
  final Function(String) onNameChanged;

  const ProfileScreen({super.key, required this.onNameChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController nameController = TextEditingController();
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF364B9A), // navy
        foregroundColor: Colors.white, // white text
        title: Text("Settings"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),

          Text(
            "Your Name",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white, // white stands out
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: nameController,
              onChanged: (value) {
                widget.onNameChanged(value);
              },
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,), // white text
              decoration: InputDecoration(
                hintText: "Enter your name",
                hintStyle: TextStyle(color: const Color(0xFFFDB366), fontSize: 20, fontWeight: FontWeight.bold,),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFFDB366)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFFDB366)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFFFDB366),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),
          Text(
            "Voice",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 250,
            child: DropdownButton<Map<String, String>>(
              isExpanded: true,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              dropdownColor: const Color(0xFF364B9A), // navy dropdown
              hint: Text(
                "Select Voice",
                style: TextStyle(color: const Color(0xFFFDB366)), // orange
              ),
           //   hint: Text(
          //      "Select Voice",
           //     //style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //    ),
              value: TTSSettings.selectedVoice,
              items: TTSSettings.voices.map((voice) {
                //final v = Map<String, String>.from(voice);
                return DropdownMenuItem(
                  value: voice,
                  child: Text(
                    voice['name'] ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (voice) async {
                setState(() {
                  TTSSettings.selectedVoice = voice;
                });

                await TTSSettings.tts.setVoice(voice!);

                await TTSSettings.tts.speak(
                  "Voice changed to ${voice['name']}",
                );
              },
            ),
          ),
          Text(
            "Speed",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Slider(
            activeColor: const Color(0xFFFDB366), // orange
            inactiveColor: Colors.white24, // light contrast
            value: TTSSettings.speechRate,
            min: 0.2,
            max: 2.0,
            divisions: 8,
            label: TTSSettings.speechRate.toStringAsFixed(2),
            onChanged: (value) {
              TTSSettings.tts.speak(
                "Speech rate set to ${value.toStringAsFixed(2)}",
              );
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
