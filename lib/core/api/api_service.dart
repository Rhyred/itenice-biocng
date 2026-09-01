import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/runtime_config.dart';
import '../config/runtime_config_store.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// A provider for the [ApiService] instance.
final apiServiceProvider = Provider<ApiService>((ref) {
  final runtimeConfig = ref.watch(runtimeConfigProvider);
  final authState = ref.watch(authProvider);

  final dio = Dio(BaseOptions(
    baseUrl: runtimeConfig.effectiveApiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  if (authState.user?.token != null && authState.user!.token!.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer ${authState.user!.token}';
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      debugPrint('[REST Request] ${options.method} ${options.uri}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      debugPrint('[REST Response] ${response.statusCode} ${response.requestOptions.uri}');
      return handler.next(response);
    },
    onError: (DioException e, handler) {
      debugPrint('[REST Error] ${e.requestOptions.method} ${e.requestOptions.uri}');
      debugPrint('  Base URL: ${dio.options.baseUrl}');
      debugPrint('  Status: ${e.response?.statusCode}');
      debugPrint('  Type: ${e.type}');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Error: ${e.error}');
      return handler.next(e);
    },
  ));

  return ApiService(dio);
});

/// A service that handles REST API communication using [Dio].
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// Standardized health check test against a candidate base URL.
  static Future<bool> testApiConnection(String baseUrl) async {
    final formattedUrl = RuntimeConfig.formatApiUrl(baseUrl);
    debugPrint('[ApiService] Testing connection to: $formattedUrl/health');
    try {
      final testDio = Dio(BaseOptions(
        baseUrl: formattedUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final response = await testDio.get('/health');
      debugPrint('[ApiService] Connection test SUCCESS ($formattedUrl/health) — Status ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Connection test FAILED ($formattedUrl/health)');
      if (e is DioException) {
        debugPrint('  DioException type: ${e.type}');
        debugPrint('  DioException message: ${e.message}');
        debugPrint('  DioException error: ${e.error}');
        debugPrint('  HTTP Status: ${e.response?.statusCode}');
      } else {
        debugPrint('  Error: $e');
      }
      return false;
    }
  }

  /// Calls the backend health endpoint.
  Future<Response> getHealth() async {
    try {
      return await _dio.get('/health');
    } on DioException {
      rethrow;
    }
  }

  /// Authenticates user credentials with the backend.
  Future<Response> login(String username, String password) async {
    try {
      return await _dio.post('/auth/login', data: {
        'username': username,
        'email': username,
        'password': password,
      });
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
