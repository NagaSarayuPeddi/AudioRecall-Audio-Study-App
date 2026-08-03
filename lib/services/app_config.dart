import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
      print('AppConfig: .env loaded successfully');
      print(
        'AppConfig: key present = ${dotenv.env.containsKey('COHERE_API_KEY')}',
      );
    } catch (e) {
      // Common causes:
      //   - .env not listed under assets in pubspec.yaml
      //   - .env file doesn't exist at the project root
      //   - flutter pub get not re-run after adding the asset
      print('AppConfig: failed to load .env — $e');
      print(
        'AppConfig: check that .env is in your project root AND listed under assets in pubspec.yaml',
      );
      _initialized = false;
    }
  }

  static String get cohereApiKey {
    if (!_initialized) {
      throw StateError(
        'AppConfig.init() was not awaited before using cohereApiKey.\n'
        'Make sure main() calls: await AppConfig.init()',
      );
    }

    final key = dotenv.env['COHERE_API_KEY'];

    if (key == null || key.isEmpty) {
      throw StateError(
        'COHERE_API_KEY is missing from your .env file.\n'
        'Your .env file should contain:\n'
        '  COHERE_API_KEY=your_key_here',
      );
    }

    if (key == 'your_cohere_api_key_here') {
      throw StateError(
        'COHERE_API_KEY is still set to the placeholder value.\n'
        'Replace it with your real key from cohere.ai',
      );
    }

    return key;
  }

  /// Safe check — returns true only if key is present and not a placeholder
  static bool get isConfigured {
    if (!_initialized) return false;
    final key = dotenv.env['COHERE_API_KEY'];
    return key != null && key.isNotEmpty && key != 'your_cohere_api_key_here';
  }
}
