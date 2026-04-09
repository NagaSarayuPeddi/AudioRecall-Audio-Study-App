import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructionScreen extends StatelessWidget {
  final VoidCallback onImportCsv;
  final VoidCallback onGenerateAI;

  const InstructionScreen({
    super.key,
    required this.onImportCsv,
    required this.onGenerateAI,
  });
  //const Color(0xFF364B9A), // navy
  //          secondary: const Color(0xFFFDB366), // orange


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFF364B9A),
      appBar: AppBar(title: const Text("Instructions"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Through EchoLearn, you can learn through audio instruction, generate study sets with AI, or import your own CSV files.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 35, fontWeight: FontWeight.w800, color: const Color(0xFFFDB366)),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFFFDB366),
                  foregroundColor: const Color(0xFF364B9A),
                ),
                child: const Text("Import CSV", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFFFDB366),
                  foregroundColor: const Color(0xFF364B9A),
                ),
                child: const Text(
                  "Generate with AI",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
