import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/features/devices/presentation/pages/device_detail_page.dart';
import 'package:itenice_bio_cng/features/devices/presentation/providers/device_provider.dart';
import 'package:itenice_bio_cng/shared/models/device_model.dart';

void main() {
  testWidgets('DeviceDetailPage renders metadata correctly', (tester) async {
    final device = DeviceModel(
      id: 'uuid-123',
      name: 'Test Device',
      type: 'ESP32',
      status: 'ONLINE',
      firmware: '1.2.3',
      lastSeen: DateTime.parse('2026-08-25T12:00:00Z'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceDetailProvider('uuid-123').overrideWith((ref) => device),
        ],
        child: const MaterialApp(
          home: DeviceDetailPage(deviceId: 'uuid-123'),
        ),
      ),
    );

    await tester.pump();

    // Data rendered
    expect(find.text('Test Device'), findsOneWidget);
    expect(find.text('ESP32'), findsNWidgets(2)); // Title and Detail Item
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('uuid-123'), findsOneWidget);
  });
}
