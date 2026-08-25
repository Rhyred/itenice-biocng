import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/telemetry/presentation/providers/telemetry_provider.dart';

@GenerateMocks([ApiService])
import 'telemetry_provider_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  final startTime = DateTime(2023, 10, 27, 10, 0);
  final endTime = DateTime(2023, 10, 27, 12, 0);
  final params = TelemetryParams(
    deviceId: 'device-1',
    startTime: startTime,
    endTime: endTime,
  );

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

  group('telemetryProvider', () {
    test('initialization and data fetching', () async {
      final container = createContainer();
      final mockData = {
        'data': [
          {
            'timestamp': '2023-10-27T10:00:00Z',
            'metrics': {
              'temp': {'v': 25.5, 'u': 'C'}
            },
          }
        ],
        'meta': {
          'total_count': 1,
          'current_page': 1,
          'limit': 100,
          'total_pages': 1,
        }
      };

      when(mockApiService.getTelemetry(
        deviceId: 'device-1',
        startTime: startTime,
        endTime: endTime,
        page: 1,
      )).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/telemetry'),
        ),
      );

      final result = await container.read(telemetryProvider(params).future);

      expect(result.data.length, 1);
      expect(result.data[0].metrics['temp']?.value, 25.5);
      verify(mockApiService.getTelemetry(
        deviceId: 'device-1',
        startTime: startTime,
        endTime: endTime,
        page: 1,
      )).called(1);
    });

    test('load more functionality', () async {
      final container = createContainer();

      final page1Data = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'timestamp': '2023-10-27T10:00:00Z',
            'metrics': <String, dynamic>{},
          }
        ],
        'meta': <String, dynamic>{
          'total_count': 2,
          'current_page': 1,
          'limit': 1,
          'total_pages': 2,
        }
      };

      final page2Data = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'timestamp': '2023-10-27T10:05:00Z',
            'metrics': <String, dynamic>{},
          }
        ],
        'meta': <String, dynamic>{
          'total_count': 2,
          'current_page': 2,
          'limit': 1,
          'total_pages': 2,
        }
      };

      when(mockApiService.getTelemetry(
        deviceId: 'device-1',
        startTime: startTime,
        endTime: endTime,
        page: 1,
      )).thenAnswer((_) async => Response(
            data: page1Data,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/telemetry'),
          ));

      when(mockApiService.getTelemetry(
        deviceId: 'device-1',
        startTime: startTime,
        endTime: endTime,
        page: 2,
      )).thenAnswer((_) async => Response(
            data: page2Data,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/telemetry'),
          ));

      // Initial load
      await container.read(telemetryProvider(params).future);

      // Load more
      await container.read(telemetryProvider(params).notifier).loadMore();

      final state = container.read(telemetryProvider(params)).value!;
      expect(state.data.length, 2);
      expect(state.meta.currentPage, 2);
    });

    test('error handling for invalid date ranges', () async {
      final container = createContainer();
      final invalidParams = TelemetryParams(
        deviceId: 'device-1',
        startTime: endTime, // Start after end
        endTime: startTime,
      );

      expect(
        () => container.read(telemetryProvider(invalidParams).future),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
