import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider for the [ApiService] instance.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(Dio());
});

/// A service that handles REST API communication using [Dio].
class ApiService {
  final Dio _dio;

  ApiService(this._dio) {
    _initializeDio();
  }

  void _initializeDio() {
    // Basic configuration. 
    // URLs and secrets must be injected from environment variables in later phases.
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    
    // Add interceptors here for logging, authentication, etc.
  }

  /// Example GET request.
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  /// Example POST request.
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException {
      rethrow;
    }
  }
}
