import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([Dio])
import 'api_service_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    apiService = ApiService(mockDio);
  });

  group('ApiService', () {
    test('getHealth should return success response', () async {
      when(mockDio.get('/health')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/health'),
          data: {'status': 'ok'},
          statusCode: 200,
        ),
      );

      final response = await apiService.getHealth();

      expect(response.statusCode, 200);
      expect(response.data['status'], 'ok');
    });

    test('getTelemetry should construct correct query parameters', () async {
      final startTime = DateTime(2023, 10, 27, 10, 0);
      final endTime = DateTime(2023, 10, 27, 12, 0);

      when(mockDio.get(
        '/telemetry',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/telemetry'),
          data: {
            'data': [],
            'meta': {
              'total_count': 0,
              'current_page': 1,
              'limit': 100,
              'total_pages': 0,
            }
          },
          statusCode: 200,
        ),
      );

      await apiService.getTelemetry(
        deviceId: 'device-1',
        startTime: startTime,
        endTime: endTime,
        component: 'temp-sensor',
        page: 2,
        limit: 50,
      );

      verify(mockDio.get(
        '/telemetry',
        queryParameters: {
          'device_id': 'device-1',
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'page': 2,
          'limit': 50,
          'component': 'temp-sensor',
        },
      )).called(1);
    });
  });
}
