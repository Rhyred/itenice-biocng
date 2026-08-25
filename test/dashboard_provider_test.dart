import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:itenice_bio_cng/shared/models/project_model.dart';

class MultiPathMockDio extends Fake implements Dio {
  final Map<String, dynamic> Function(String path, Map<String, dynamic>? queryParameters) responseMapper;

  MultiPathMockDio(this.responseMapper);

  @override
  BaseOptions options = BaseOptions();

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final responseData = responseMapper(path, queryParameters);
      return Response(
        requestOptions: RequestOptions(path: path),
        data: responseData as T,
        statusCode: 200,
      );
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e,
      );
    }
  }
}

void main() {
  group('DashboardProvider', () {
    test('should aggregate dashboard data correctly', () async {
      final mockProject = const ProjectModel(id: 'p1', name: 'Project 1', location: 'Loc 1');
      
      final mockDevices = {
        'data': [
          {'id': 'd1', 'name': 'Device 1', 'status': 'ONLINE', 'type': 'ESP32'},
          {'id': 'd2', 'name': 'Device 2', 'status': 'OFFLINE', 'type': 'ESP32'},
        ],
        'meta': {'total_count': 2, 'current_page': 1, 'limit': 20, 'total_pages': 1}
      };

      final mockAlerts = {
        'data': [
          {
            'id': 'a1',
            'device_id': 'd1',
            'severity': 'CRITICAL',
            'status': 'ACTIVE',
            'message': 'Critical Alert',
            'timestamp': DateTime.now().toIso8601String(),
            'component': 'Sensor'
          }
        ],
        'meta': {'total_count': 1, 'current_page': 1, 'limit': 20, 'total_pages': 1}
      };

      final mockTelemetry = {
        'data': [
          {
            'timestamp': DateTime.now().toIso8601String(),
            'device_id': 'd1',
            'metrics': {
              'temp': {'v': 25.5, 'u': 'C'}
            }
          }
        ],
        'meta': {'total_count': 1, 'current_page': 1, 'limit': 20, 'total_pages': 1}
      };

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(MultiPathMockDio((path, params) {
            if (path == '/devices') return mockDevices;
            if (path == '/alerts') return mockAlerts;
            if (path == '/telemetry') return mockTelemetry;
            return {};
          }))),
        ],
      );

      // Set selected project
      container.read(selectedProjectProvider.notifier).state = mockProject;

      final summary = await container.read(dashboardDataProvider.future);

      expect(summary.totalDevices, 2);
      expect(summary.onlineDevices, 1);
      expect(summary.offlineDevices, 1);
      expect(summary.criticalAlerts, 2); // 1 per device fetch (we have 2 devices in mockDevices)
      // Actually my provider fetches alerts for each device.
      // d1 has 1 alert, d2 has 1 alert (mockAlerts is returned for any /alerts call)
      // so 1 + 1 = 2 critical alerts.
      expect(summary.activeAlerts, 2);
      expect(summary.latestTelemetry.length, 2); 
    });

    test('should throw error if no project selected', () async {
      final container = ProviderContainer();
      
      expect(
        () => container.read(dashboardDataProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
