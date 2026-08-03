import 'package:flutter/material.dart';

/// A microphone button that is fully accessible to VoiceOver and TalkBack.
///
/// Replaces all the raw GestureDetector + Container mic buttons scattered
/// across study_set.dart and flash_card.dart with a single reusable widget
/// that has correct semantics, focus handling, and visual state.
///
/// Usage:
///   AccessibleMicButton(
///     isListening: isListeningQuestion,
///     fieldLabel: 'question',   // used in the accessibility label
///     onTap: () async { ... },
///   )
class AccessibleMicButton extends StatelessWidget {
  final bool isListening;

  /// Short label for what field this mic is recording, e.g. 'question',
  /// 'answer', 'set name'. Used to build the accessibility label.
  final String fieldLabel;

  final VoidCallback onTap;

  /// Size of the circular button. Defaults to 80 to match existing design.
  final double size;

  const AccessibleMicButton({
    super.key,
    required this.isListening,
    required this.fieldLabel,
    required this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final label = isListening
        ? 'Stop recording $fieldLabel'
        : 'Record $fieldLabel by voice';

    final hint = isListening
        ? 'Tap to stop the microphone'
        : 'Tap to speak the $fieldLabel aloud';

    return Semantics(
      label: label,
      hint: hint,
      button: true,
      // Tell screen readers the current toggle state
      toggled: isListening,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            // Pulse red while listening so sighted users also see state
            color: isListening ? Colors.red.shade600 : Colors.purple,
            shape: BoxShape.circle,
            boxShadow: isListening
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: size * 0.6,
            // Exclude the icon from semantics — the parent Semantics
            // node already provides the full label
            semanticLabel: '',
          ),
        ),
      ),
    );
  }
}
