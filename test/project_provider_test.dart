import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/projects/presentation/providers/project_provider.dart';

class MockDio extends Fake implements Dio {
  final Map<String, dynamic> responseData;
  final int statusCode;

  MockDio({required this.responseData, this.statusCode = 200});

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
    if (statusCode != 200) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: statusCode,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      data: responseData as T,
      statusCode: statusCode,
    );
  }
}

void main() {
  group('ProjectProvider', () {
    test('should return ProjectListResponse on success', () async {
      final mockData = {
        'data': [
          {'id': '1', 'name': 'Test Project', 'location': 'Test Location'}
        ],
        'meta': {
          'total_count': 1,
          'current_page': 1,
          'limit': 20,
          'total_pages': 1,
        }
      };

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(MockDio(responseData: mockData))),
        ],
      );

      final result = await container.read(projectProvider.future);

      expect(result.data.length, 1);
      expect(result.data[0].name, 'Test Project');
      expect(result.meta.totalCount, 1);
    });

    test('should throw error when API fails', () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(MockDio(responseData: {}, statusCode: 500)),
          ),
        ],
      );

      expect(
        () => container.read(projectProvider.future),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle empty data', () async {
      final mockData = {
        'data': [],
        'meta': {
          'total_count': 0,
          'current_page': 1,
          'limit': 20,
          'total_pages': 0,
        }
      };

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(MockDio(responseData: mockData))),
        ],
      );

      final result = await container.read(projectProvider.future);

      expect(result.data, isEmpty);
      expect(result.meta.totalCount, 0);
    });
  });
}
