import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class Bell {
  static final AudioPlayer _startPlayer = AudioPlayer();
  static final AudioPlayer _warningPlayer = AudioPlayer();
  static final AudioPlayer _endPlayer = AudioPlayer();

  static const String _start = 'assets/audio/bell_start.wav';
  static const String _warning = 'assets/audio/bell_warning.wav';
  static const String _end = 'assets/audio/bell_end.wav';

  static bool _initialized = false;

  // =====================================================
  // Preferred API
  // =====================================================

  static Future<void> playStartBell() => _playStart();
  static Future<void> playWarningBell() => _playWarning();
  static Future<void> playEndBell() => _playEnd();

  // =====================================================
  // Backward-compatible aliases
  // =====================================================

  static Future<void> ringStart() => playStartBell();
  static Future<void> ringWarning() => playWarningBell();
  static Future<void> ringEnd() => playEndBell();

  // =====================================================
  // Internal setup
  // =====================================================

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      await _startPlayer.setAsset(_start);
      await _warningPlayer.setAsset(_warning);
      await _endPlayer.setAsset(_end);
      _initialized = true;
    } catch (e) {
      debugPrint('Bell init error: $e');
      rethrow;
    }
  }

  static Future<void> _playStart() async {
    try {
      await _ensureInitialized();
      await _startPlayer.seek(Duration.zero);
      await _startPlayer.play();
    } catch (e) {
      debugPrint('Bell error ($_start): $e');
    }
  }

  static Future<void> _playWarning() async {
    try {
      await _ensureInitialized();
      await _warningPlayer.seek(Duration.zero);
      await _warningPlayer.play();
    } catch (e) {
      debugPrint('Bell error ($_warning): $e');
    }
  }

  static Future<void> _playEnd() async {
    try {
      await _ensureInitialized();
      await _endPlayer.seek(Duration.zero);
      await _endPlayer.play();
    } catch (e) {
      debugPrint('Bell error ($_end): $e');
    }
  }

  static Future<void> dispose() async {
    try {
      await _startPlayer.dispose();
    } catch (_) {}

    try {
      await _warningPlayer.dispose();
    } catch (_) {}

    try {
      await _endPlayer.dispose();
    } catch (_) {}

    _initialized = false;
  }
}