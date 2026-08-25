import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/devices/presentation/providers/device_provider.dart';

@GenerateMocks([ApiService])
import 'device_provider_test.mocks.dart';

void main() {
  late MockApiService mockApiService;

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

  group('deviceListProvider', () {
    test('fetches devices successfully', () async {
      final container = createContainer();
      final mockData = {
        'data': [
          {
            'id': 'd1',
            'name': 'Device 1',
            'type': 'ESP32',
            'status': 'ONLINE',
          }
        ],
        'meta': {
          'total_count': 1,
          'current_page': 1,
          'limit': 20,
          'total_pages': 1,
        }
      };

      when(mockApiService.getDevices(projectId: 'p1')).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/devices'),
        ),
      );

      final result = await container.read(deviceListProvider('p1').future);

      expect(result.data.length, 1);
      expect(result.data[0].name, 'Device 1');
      verify(mockApiService.getDevices(projectId: 'p1')).called(1);
    });

    test('handles empty device list', () async {
      final container = createContainer();
      final mockData = {
        'data': [],
        'meta': {
          'total_count': 0,
          'current_page': 1,
          'limit': 20,
          'total_pages': 0,
        }
      };

      when(mockApiService.getDevices(projectId: 'p1')).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/devices'),
        ),
      );

      final result = await container.read(deviceListProvider('p1').future);

      expect(result.data, isEmpty);
    });

    test('throws exception on API error', () async {
      final container = createContainer();

      when(mockApiService.getDevices(projectId: 'p1')).thenAnswer(
        (_) async => Response(
          data: 'Error',
          statusCode: 500,
          statusMessage: 'Internal Server Error',
          requestOptions: RequestOptions(path: '/devices'),
        ),
      );

      expect(
        () => container.read(deviceListProvider('p1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deviceDetailProvider', () {
    test('fetches device details successfully', () async {
      final container = createContainer();
      final mockData = {
        'id': 'd1',
        'name': 'Device 1',
        'type': 'ESP32',
        'status': 'ONLINE',
        'firmware': '1.0.0',
      };

      when(mockApiService.getDeviceById('d1')).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/devices/d1'),
        ),
      );

      final result = await container.read(deviceDetailProvider('d1').future);

      expect(result.id, 'd1');
      expect(result.name, 'Device 1');
      verify(mockApiService.getDeviceById('d1')).called(1);
    });
  });
}
