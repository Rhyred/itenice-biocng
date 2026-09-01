import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/features/auth/presentation/providers/auth_provider.dart';

class FakeApiService extends Fake implements ApiService {
  Future<Response> Function(String username, String password)? onLogin;

  @override
  Future<Response> login(String username, String password) async {
    if (onLogin != null) {
      return await onLogin!(username, password);
    }
    throw UnimplementedError();
  }
}

void main() {
  group('REAL MODE Authentication Tests', () {
    late FakeApiService fakeApiService;
    late ProviderContainer container;

    setUp(() {
      fakeApiService = FakeApiService();
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(fakeApiService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Successful backend login sets authenticated state and session token',
        () async {
      fakeApiService.onLogin = (username, password) async {
        if (username == 'operator_real' && password == 'secret123') {
          return Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'token': 'jwt_real_operator_token_123',
              'user': {
                'id': 'op-001',
                'name': 'Budi Operator',
                'role': 'operator',
              }
            },
          );
        }
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        );
      };

      final success = await container
          .read(authProvider.notifier)
          .login('operator_real', 'secret123');

      expect(success, isTrue);
      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.user?.displayName, equals('Budi Operator'));
      expect(authState.user?.role, equals('operator'));
      expect(authState.user?.token, equals('jwt_real_operator_token_123'));
    });

    test('Failed backend login returns false and sets readable error message',
        () async {
      fakeApiService.onLogin = (username, password) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: {
              'error': {
                'code': 'INVALID_CREDENTIALS',
                'message': 'Username atau password salah',
              }
            },
          ),
        );
      };

      final success = await container
          .read(authProvider.notifier)
          .login('wrong_user', 'wrong_pass');

      expect(success, isFalse);
      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, isFalse);
      expect(authState.error, contains('Username atau password salah'));
    });
  });
}
