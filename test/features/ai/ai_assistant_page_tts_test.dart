import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:itenice_bio_cng/features/ai/presentation/controllers/tts_controller.dart';
import 'tts_controller_test.dart';

void main() {
  group('AiAssistantPage TTS Widget Tests', () {
    late FakeTtsEngine fakeEngine;

    setUp(() {
      fakeEngine = FakeTtsEngine();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          ttsEngineProvider.overrideWithValue(fakeEngine),
        ],
        child: const MaterialApp(
          home: AiAssistantPage(),
        ),
      );
    }

    testWidgets('Renders Read button on AI assistant message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsAtLeast(1));
      expect(find.byIcon(Icons.volume_up_rounded), findsAtLeast(1));
    });

    testWidgets('Tapping Read triggers TTS speak and changes button to Stop',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final readBtn = find.text('Read').first;
      await tester.tap(readBtn);
      await tester.pump();

      expect(fakeEngine.isSpeaking, isTrue);
      expect(fakeEngine.lastSpokenText, contains('Halo! Ada yang ingin ditanyakan'));
      expect(find.text('Stop'), findsOneWidget);

      final stopBtn = find.text('Stop').first;
      await tester.tap(stopBtn);
      await tester.pump();

      expect(fakeEngine.isSpeaking, isFalse);
      expect(find.text('Read'), findsAtLeast(1));
    });
  });
}
