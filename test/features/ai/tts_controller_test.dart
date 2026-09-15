import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/features/ai/presentation/controllers/tts_controller.dart';

class FakeTtsEngine implements TtsEngine {
  bool initialized = false;
  String currentLanguage = '';
  String? lastSpokenText;
  bool isSpeaking = false;
  bool shouldFailLanguage = false;
  bool shouldFailSpeak = false;

  VoidCallback? completionHandler;
  Function(String message)? errorHandler;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  Future<bool> setLanguage(String language) async {
    if (shouldFailLanguage && language == "id-ID") {
      return false;
    }
    currentLanguage = language;
    return true;
  }

  @override
  Future<void> speak(String text) async {
    if (shouldFailSpeak) {
      throw Exception("TTS Engine Error");
    }
    lastSpokenText = text;
    isSpeaking = true;
  }

  @override
  Future<void> stop() async {
    isSpeaking = false;
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }

  @override
  void setErrorHandler(Function(String message) callback) {
    errorHandler = callback;
  }

  void triggerCompletion() {
    isSpeaking = false;
    completionHandler?.call();
  }

  void triggerError(String msg) {
    isSpeaking = false;
    errorHandler?.call(msg);
  }
}

void main() {
  group('TTS Controller & State Tests', () {
    late FakeTtsEngine fakeEngine;
    late ProviderContainer container;

    setUp(() {
      fakeEngine = FakeTtsEngine();
      container = ProviderContainer(
        overrides: [
          ttsEngineProvider.overrideWithValue(fakeEngine),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initializes with id-ID preferred', () async {
      container.read(ttsProvider.notifier);
      await Future.delayed(Duration.zero);

      expect(fakeEngine.initialized, isTrue);
      expect(fakeEngine.currentLanguage, equals('id-ID'));
      expect(container.read(ttsProvider).status, equals(TtsStatus.idle));
    });

    test('Fallbacks to en-US if id-ID unavailable', () async {
      fakeEngine.shouldFailLanguage = true;
      container.read(ttsProvider.notifier);
      await Future.delayed(Duration.zero);

      expect(fakeEngine.currentLanguage, equals('en-US'));
    });

    test('Speak updates status to speaking and sets active message', () async {
      final notifier = container.read(ttsProvider.notifier);
      await notifier.speak(messageId: 'msg_1', text: 'Halo BioCNG');

      final state = container.read(ttsProvider);
      expect(state.status, equals(TtsStatus.speaking));
      expect(state.activeMessageId, equals('msg_1'));
      expect(fakeEngine.lastSpokenText, equals('Halo BioCNG'));
    });

    test('Stop updates status to stopped and clears active message', () async {
      final notifier = container.read(ttsProvider.notifier);
      await notifier.speak(messageId: 'msg_1', text: 'Halo BioCNG');
      await notifier.stop();

      final state = container.read(ttsProvider);
      expect(state.status, equals(TtsStatus.stopped));
      expect(state.activeMessageId, isNull);
    });

    test('Speaking a new message stops previous speech first', () async {
      final notifier = container.read(ttsProvider.notifier);
      await notifier.speak(messageId: 'msg_1', text: 'Pesan pertama');
      expect(container.read(ttsProvider).activeMessageId, equals('msg_1'));

      await notifier.speak(messageId: 'msg_2', text: 'Pesan kedua');
      expect(container.read(ttsProvider).activeMessageId, equals('msg_2'));
      expect(fakeEngine.lastSpokenText, equals('Pesan kedua'));
    });

    test('Handles engine speech failure gracefully', () async {
      fakeEngine.shouldFailSpeak = true;
      final notifier = container.read(ttsProvider.notifier);
      await notifier.speak(messageId: 'msg_1', text: 'Test fail');

      final state = container.read(ttsProvider);
      expect(state.status, equals(TtsStatus.error));
      expect(state.errorMessage, equals('TTS tidak tersedia'));
      expect(state.activeMessageId, isNull);
    });

    test('Completion callback sets state back to idle', () async {
      final notifier = container.read(ttsProvider.notifier);
      await notifier.speak(messageId: 'msg_1', text: 'Completed speech');
      expect(container.read(ttsProvider).status, equals(TtsStatus.speaking));

      fakeEngine.triggerCompletion();
      expect(container.read(ttsProvider).status, equals(TtsStatus.idle));
      expect(container.read(ttsProvider).activeMessageId, isNull);
    });
  });
}
