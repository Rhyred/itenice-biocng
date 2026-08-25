import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/features/health/data/models/health_status.dart';

void main() {
  group('HealthStatus Model', () {
    test('should parse JSON correctly', () {
      final json = {
        'status': 'ok',
        'service': 'nicegas-api',
        'database': 'connected',
      };

      final health = HealthStatus.fromJson(json);

      expect(health.status, 'ok');
      expect(health.service, 'nicegas-api');
      expect(health.database, 'connected');
      expect(health.isHealthy, isTrue);
    });

    test('should handle missing fields with default values', () {
      final json = <String, dynamic>{};

      final health = HealthStatus.fromJson(json);

      expect(health.status, 'unknown');
      expect(health.service, 'unknown');
      expect(health.database, 'unknown');
      expect(health.isHealthy, isFalse);
    });

    test('isHealthy should return false if status is not ok', () {
      final health = HealthStatus(
        status: 'error',
        service: 'api',
        database: 'connected',
      );
      expect(health.isHealthy, isFalse);
    });

    test('isHealthy should return false if database is not connected', () {
      final health = HealthStatus(
        status: 'ok',
        service: 'api',
        database: 'disconnected',
      );
      expect(health.isHealthy, isFalse);
    });
  });
}
