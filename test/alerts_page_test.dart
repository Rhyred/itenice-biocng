import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/alerts/presentation/pages/alerts_page.dart';
import 'telemetry_provider_test.mocks.dart';

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
      child: const MaterialApp(
        home: AlertsPage(),
      ),
    );
  }

  testWidgets('AlertsPage shows loading state then alerts list', (WidgetTester tester) async {
    final mockData = {
      'data': [
        {
          'id': 'alert-1',
          'device_id': 'device-1',
          'component': 'digester',
          'severity': 'CRITICAL',
          'status': 'ACTIVE',
          'message': 'High pressure',
          'timestamp': '2023-10-27T10:00:00Z',
        }
      ],
      'meta': {
        'total_count': 1,
        'current_page': 1,
        'limit': 20,
        'total_pages': 1,
      }
    };

    when(mockApiService.getAlerts(
      page: 1,
      severity: anyNamed('severity'),
      status: anyNamed('status'),
      deviceId: anyNamed('deviceId'),
    )).thenAnswer((_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/alerts'),
        ));

    await tester.pumpWidget(createTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('High pressure'), findsOneWidget);
    expect(find.text('CRITICAL'), findsNWidgets(2)); // Filter chip and Alert card
    expect(find.text('ACTIVE'), findsNWidgets(2)); // Filter chip and Alert card
  });

  testWidgets('AlertsPage shows empty state', (WidgetTester tester) async {
    final mockData = {
      'data': [],
      'meta': {
        'total_count': 0,
        'current_page': 1,
        'limit': 20,
        'total_pages': 0,
      }
    };

    when(mockApiService.getAlerts(
      page: 1,
      severity: anyNamed('severity'),
      status: anyNamed('status'),
      deviceId: anyNamed('deviceId'),
    )).thenAnswer((_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/alerts'),
        ));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No alerts found.'), findsOneWidget);
  });

  testWidgets('AlertsPage shows error state and retry works', (WidgetTester tester) async {
    when(mockApiService.getAlerts(
      page: 1,
      severity: anyNamed('severity'),
      status: anyNamed('status'),
      deviceId: anyNamed('deviceId'),
    )).thenAnswer((_) async => throw Exception('Network Error'));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Network Error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Update mock for success
    when(mockApiService.getAlerts(
      page: 1,
      severity: anyNamed('severity'),
      status: anyNamed('status'),
      deviceId: anyNamed('deviceId'),
    )).thenAnswer((_) async => Response(
          data: {
            'data': [],
            'meta': {'total_count': 0, 'current_page': 1, 'limit': 20, 'total_pages': 0}
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/alerts'),
        ));

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No alerts found.'), findsOneWidget);
  });
}
