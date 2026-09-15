import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, speaking, stopped, error }

class TtsState {
  final TtsStatus status;
  final String? activeMessageId;
  final String? errorMessage;

  const TtsState({
    this.status = TtsStatus.idle,
    this.activeMessageId,
    this.errorMessage,
  });
}

/// Abstract TTS engine wrapper to allow mocking/testing without native platform channel failures
abstract class TtsEngine {
  Future<void> init();
  Future<bool> setLanguage(String language);
  Future<void> speak(String text);
  Future<void> stop();
  void setCompletionHandler(VoidCallback callback);
  void setErrorHandler(Function(String message) callback);
}

class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  Future<void> init() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  @override
  Future<bool> setLanguage(String language) async {
    try {
      final result = await _flutterTts.setLanguage(language);
      return result == 1 || result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    _flutterTts.setCompletionHandler(callback);
  }

  @override
  void setErrorHandler(Function(String message) callback) {
    _flutterTts.setErrorHandler((msg) => callback(msg.toString()));
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  final TtsEngine _engine;
  bool _initialized = false;

  TtsNotifier(this._engine) : super(const TtsState()) {
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      await _engine.init();
      _engine.setCompletionHandler(() {
        if (mounted) {
          state = const TtsState(
            status: TtsStatus.idle,
            activeMessageId: null,
          );
        }
      });
      _engine.setErrorHandler((msg) {
        if (mounted) {
          state = TtsState(
            status: TtsStatus.error,
            activeMessageId: null,
            errorMessage: msg,
          );
        }
      });

      // Prefer Indonesian, fallback to English
      bool isIndonesianAvailable = await _engine.setLanguage("id-ID");
      if (!isIndonesianAvailable) {
        await _engine.setLanguage("en-US");
      }
      _initialized = true;
    } catch (e) {
      if (mounted) {
        state = const TtsState(
          status: TtsStatus.error,
          errorMessage: "TTS tidak tersedia",
        );
      }
    }
  }

  Future<void> speak({required String messageId, required String text}) async {
    if (text.trim().isEmpty) return;

    try {
      // If currently speaking a message, stop first
      if (state.status == TtsStatus.speaking) {
        await stop();
      }

      state = TtsState(
        status: TtsStatus.speaking,
        activeMessageId: messageId,
        errorMessage: null,
      );

      if (!_initialized) {
        await _initEngine();
      }

      await _engine.speak(text);
    } catch (e) {
      if (mounted) {
        state = const TtsState(
          status: TtsStatus.error,
          activeMessageId: null,
          errorMessage: "TTS tidak tersedia",
        );
      }
    }
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Ignore stop errors
    } finally {
      if (mounted) {
        state = const TtsState(
          status: TtsStatus.stopped,
          activeMessageId: null,
        );
      }
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final ttsEngineProvider = Provider<TtsEngine>((ref) => FlutterTtsEngine());

final ttsProvider =
    StateNotifierProvider.autoDispose<TtsNotifier, TtsState>((ref) {
  final engine = ref.watch(ttsEngineProvider);
  return TtsNotifier(engine);
});
