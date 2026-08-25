import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// A provider for the [ApiService] instance.
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  return ApiService(dio);
});

/// A service that handles REST API communication using [Dio].
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// Calls the backend health endpoint.
  Future<Response> getHealth() async {
    try {
      return await _dio.get('/health');
    } on DioException {
      rethrow;
    }
  }

  /// Fetches a paginated list of projects.
  Future<Response> getProjects({int page = 1, int limit = 20}) async {
    try {
      return await _dio.get('/projects', queryParameters: {
        'page': page,
        'limit': limit,
      });
    } on DioException {
      rethrow;
    }
  }

  /// Fetches a paginated list of devices, optionally filtered by project.
  Future<Response> getDevices({
    String? projectId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (projectId != null) {
        queryParams['project_id'] = projectId;
      }
      return await _dio.get('/devices', queryParameters: queryParams);
    } on DioException {
      rethrow;
    }
  }

  /// Fetches a single device by its ID.
  Future<Response> getDeviceById(String deviceId) async {
    try {
      return await _dio.get('/devices/$deviceId');
    } on DioException {
      rethrow;
    }
  }

  /// Fetches a paginated list of telemetry records for a device and time range.
  Future<Response> getTelemetry({
    required String deviceId,
    required DateTime startTime,
    required DateTime endTime,
    String? component,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'device_id': deviceId,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'page': page,
        'limit': limit,
      };
      if (component != null) {
        queryParams['component'] = component;
      }
      return await _dio.get('/telemetry', queryParameters: queryParams);
    } on DioException {
      rethrow;
    }
  }

  /// Fetches a paginated list of alerts with optional filters.
  Future<Response> getAlerts({
    String? severity,
    String? status,
    String? deviceId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (severity != null) queryParams['severity'] = severity;
      if (status != null) queryParams['status'] = status;
      if (deviceId != null) queryParams['device_id'] = deviceId;

      return await _dio.get('/alerts', queryParameters: queryParams);
    } on DioException {
      rethrow;
    }
  }

  /// Generic GET request.
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  /// Generic POST request.
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException {
      rethrow;
    }
  }
}
