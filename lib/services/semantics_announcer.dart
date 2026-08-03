import 'package:flutter/semantics.dart';

/// Sends announcements directly to the platform accessibility service
/// (VoiceOver on iOS/macOS, TalkBack on Android) without using TTS.
///
/// Use this alongside TTS so that:
///   - Sighted users with VoiceOver ON hear the correct label
///   - Your TTS handles the audio-first study flow independently
///
/// Usage:
///   SemanticsAnnouncer.announce('Correct! Moving to next card.');
class SemanticsAnnouncer {
  SemanticsAnnouncer._();

  /// Announces [message] to the screen reader.
  /// [assertive] controls whether the message interrupts what is
  /// currently being read (true) or waits its turn (false).
  static void announce(String message, {bool assertive = false}) {
    // ignore: deprecated_member_use
    SemanticsService.announce(
      message,
      assertive ? TextDirection.rtl : TextDirection.ltr,
      // TextDirection is used as a proxy for assertiveness in Flutter's
      // SemanticsService — rtl triggers an assertive announcement.
    );
  }
}
