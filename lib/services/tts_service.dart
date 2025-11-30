import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service for Malayalam voice output
/// Uses device's native Malayalam voices
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Initialize TTS with Malayalam language settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set language to Malayalam
      await _flutterTts.setLanguage("ml-IN");

      // Set speech rate (0.5 = slower for clarity, 1.0 = normal)
      await _flutterTts.setSpeechRate(0.5);

      // Set volume (1.0 = maximum)
      await _flutterTts.setVolume(1.0);

      // Set pitch (1.0 = normal)
      await _flutterTts.setPitch(1.0);

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      // Set error handler
      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('✅ TTS initialized with Malayalam (ml-IN)');
    } catch (e) {
      print('❌ Error initializing TTS: $e');
      _isInitialized = false;
    }
  }

  /// Speak Malayalam text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    try {
      // Stop any ongoing speech
      await stop();

      _isSpeaking = true;
      print('🔊 Speaking Malayalam text...');
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ Error speaking text: $e');
      _isSpeaking = false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  /// Check if TTS is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Dispose and cleanup
  Future<void> dispose() async {
    await stop();
  }
}
