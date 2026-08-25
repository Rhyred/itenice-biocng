import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/features/health/data/models/health_status.dart';
import 'package:itenice_bio_cng/features/health/presentation/pages/health_page.dart';
import 'package:itenice_bio_cng/features/health/presentation/providers/health_provider.dart';

void main() {
  testWidgets('HealthPage displays health data when success', (WidgetTester tester) async {
    final health = HealthStatus(
      status: 'ok',
      service: 'nicegas-api',
      database: 'connected',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith((ref) => health),
        ],
        child: const MaterialApp(
          home: HealthPage(),
        ),
      ),
    );

    // Initial state might show loading if not handled by override correctly, 
    // but overrideWith( (ref) => health) makes it sync.
    
    expect(find.text('NICEGAS System Health'), findsOneWidget);
    expect(find.text('API Status'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('connected'), findsOneWidget);
    expect(find.text('nicegas-api'), findsOneWidget);
  });

  testWidgets('HealthPage displays error state when failure', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith((ref) => throw Exception('Connection Refused')),
        ],
        child: const MaterialApp(
          home: HealthPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Connection Error'), findsOneWidget);
    expect(find.textContaining('Connection Refused'), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
  });
}
