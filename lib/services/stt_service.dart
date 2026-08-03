import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

/// Wraps the speech_to_text plugin with:
///   - Permission checks before every listen call
///   - Graceful error callbacks instead of silent failures
///   - A reliable listenOnce() with silence detection
class STTService {
  final SpeechToText _speech = SpeechToText();
  Completer<String>? _answerCompleter;

  // ─── Initialisation ───────────────────────────────────────────────────────

  /// Returns true if mic permission was granted and STT is available.
  /// Safe to call multiple times — speech_to_text guards against double-init.
  Future<bool> initialize() async {
    if (_speech.isAvailable) return true;

    final available = await _speech.initialize(
      onStatus: (status) {
        // 'done' fires when the recogniser stops after silence
        // 'notListening' fires when stop() is called explicitly
        print('STT status: $status');
      },
      onError: (error) {
        print('STT error: ${error.errorMsg} (permanent: ${error.permanent})');
        // Complete any pending listenOnce with empty string on fatal error
        if (error.permanent &&
            _answerCompleter != null &&
            !_answerCompleter!.isCompleted) {
          _answerCompleter!.complete('');
        }
      },
    );

    if (!available) {
      print(
        'STT not available — microphone permission denied or '
        'no speech recognition engine installed.',
      );
    }

    return available;
  }

  // ─── Continuous listening (for text fields) ───────────────────────────────

  /// Starts continuous listening and calls [onResult] with each partial result.
  /// Caller is responsible for calling [stopListening] when done.
  Future<void> listen({required Function(String) onResult}) async {
    final available = await initialize();
    if (!available) return;

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  // ─── Single answer capture (for study sessions) ───────────────────────────

  /// Listens until silence is detected, then returns the recognised text.
  ///
  /// - Waits up to [maxWaitSeconds] for the student to start speaking
  /// - Completes after [silenceSeconds] of silence once speech has begun
  /// - Returns empty string on timeout or error (caller should treat as
  ///   "no answer given")
  Future<String> listenOnce({
    int maxWaitSeconds = 8,
    int silenceSeconds = 2,
  }) async {
    final available = await initialize();
    if (!available) return '';

    String lastWords = '';
    _answerCompleter = Completer<String>();
    Timer? silenceTimer;
    bool speechDetected = false;

    await _speech.listen(
      onResult: (result) {
        lastWords = result.recognizedWords;
        if (lastWords.isNotEmpty) speechDetected = true;

        // Reset silence timer each time new words arrive
        silenceTimer?.cancel();
        silenceTimer = Timer(Duration(seconds: silenceSeconds), () {
          if (!_answerCompleter!.isCompleted) {
            _answerCompleter!.complete(lastWords);
          }
        });
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );

    // Hard timeout — prevents the session hanging if the student says nothing
    try {
      lastWords = await _answerCompleter!.future.timeout(
        Duration(seconds: maxWaitSeconds),
        onTimeout: () {
          print(
            'STT listenOnce timed out after ${maxWaitSeconds}s '
            '(speech detected: $speechDetected)',
          );
          return lastWords; // return whatever we have so far
        },
      );
    } catch (e) {
      print('STT listenOnce error: $e');
      lastWords = '';
    }

    silenceTimer?.cancel();
    await _speech.stop();

    final result = lastWords.toLowerCase().trim();
    print('STT recognised: "$result"');
    return result;
  }

  // ─── Stop ────────────────────────────────────────────────────────────────

  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Whether the recogniser is currently active
  bool get isListening => _speech.isListening;

  /// Whether STT was successfully initialised
  bool get isAvailable => _speech.isAvailable;
}
