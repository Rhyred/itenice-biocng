import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/alerts/presentation/providers/alerts_provider.dart';

// Reuse existing mock from telemetry_provider_test.mocks.dart if possible, 
// or create a new one. Since MockApiService is already generated in telemetry_provider_test.mocks.dart,
// we can use it.
import 'telemetry_provider_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  final params = const AlertParams(deviceId: 'device-1');

  setUp(() {
    mockApiService = MockApiService();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
    );
  }

  group('alertsProvider', () {
    test('initialization and data fetching', () async {
      final container = createContainer();
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
        deviceId: 'device-1',
        page: 1,
      )).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/alerts'),
        ),
      );

      final result = await container.read(alertsProvider(params).future);

      expect(result.data.length, 1);
      expect(result.data[0].id, 'alert-1');
      verify(mockApiService.getAlerts(
        deviceId: 'device-1',
        page: 1,
      )).called(1);
    });

    test('load more functionality', () async {
      final container = createContainer();

      final page1Data = {
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
          'total_count': 2,
          'current_page': 1,
          'limit': 1,
          'total_pages': 2,
        }
      };

      final page2Data = {
        'data': [
          {
            'id': 'alert-2',
            'device_id': 'device-1',
            'component': 'sensor',
            'severity': 'WARNING',
            'status': 'ACTIVE',
            'message': 'Low battery',
            'timestamp': '2023-10-27T10:05:00Z',
          }
        ],
        'meta': {
          'total_count': 2,
          'current_page': 2,
          'limit': 1,
          'total_pages': 2,
        }
      };

      when(mockApiService.getAlerts(
        deviceId: 'device-1',
        page: 1,
      )).thenAnswer((_) async => Response(
            data: page1Data,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/alerts'),
          ));

      when(mockApiService.getAlerts(
        deviceId: 'device-1',
        page: 2,
      )).thenAnswer((_) async => Response(
            data: page2Data,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/alerts'),
          ));

      // Initial load
      await container.read(alertsProvider(params).future);

      // Load more
      await container.read(alertsProvider(params).notifier).loadMore();

      final state = container.read(alertsProvider(params)).value!;
      expect(state.data.length, 2);
      expect(state.meta.currentPage, 2);
    });

    test('filtering behavior construction', () async {
      final container = createContainer();
      final filteredParams = const AlertParams(
        deviceId: 'device-1',
        severity: 'CRITICAL',
        status: 'ACTIVE',
      );

      when(mockApiService.getAlerts(
        deviceId: 'device-1',
        severity: 'CRITICAL',
        status: 'ACTIVE',
        page: 1,
      )).thenAnswer((_) async => Response(
        data: {
          'data': [],
          'meta': {'total_count': 0, 'current_page': 1, 'limit': 20, 'total_pages': 0}
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/alerts'),
      ));

      await container.read(alertsProvider(filteredParams).future);

      verify(mockApiService.getAlerts(
        deviceId: 'device-1',
        severity: 'CRITICAL',
        status: 'ACTIVE',
        page: 1,
      )).called(1);
    });
   group('AlertParams equality', () {
      test('should be equal if all properties are same', () {
        const p1 = AlertParams(deviceId: 'd1', severity: 's1', status: 'st1');
        const p2 = AlertParams(deviceId: 'd1', severity: 's1', status: 'st1');
        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
      });

      test('should not be equal if any property is different', () {
        const p1 = AlertParams(deviceId: 'd1', severity: 's1', status: 'st1');
        const p2 = AlertParams(deviceId: 'd2', severity: 's1', status: 'st1');
        expect(p1, isNot(equals(p2)));
      });
    });
  });
}
