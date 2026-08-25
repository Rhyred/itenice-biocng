import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/shared/models/alert_model.dart';

void main() {
  group('AlertModel', () {
    test('fromJson should create a valid AlertModel', () {
      final json = {
        'id': 'alert-1',
        'device_id': 'device-1',
        'component': 'digester',
        'severity': 'CRITICAL',
        'status': 'ACTIVE',
        'message': 'High pressure',
        'timestamp': '2023-10-27T10:00:00Z',
      };

      final model = AlertModel.fromJson(json);

      expect(model.id, 'alert-1');
      expect(model.deviceId, 'device-1');
      expect(model.component, 'digester');
      expect(model.severity, 'CRITICAL');
      expect(model.status, 'ACTIVE');
      expect(model.message, 'High pressure');
      expect(model.timestamp.isUtc, isTrue);
    });

    test('toJson should return a valid Map', () {
      final model = AlertModel(
        id: 'alert-1',
        deviceId: 'device-1',
        component: 'digester',
        severity: 'CRITICAL',
        status: 'ACTIVE',
        message: 'High pressure',
        timestamp: DateTime.parse('2023-10-27T10:00:00Z'),
      );

      final json = model.toJson();

      expect(json['id'], 'alert-1');
      expect(json['severity'], 'CRITICAL');
      expect(json['timestamp'], contains('2023-10-27T10:00:00'));
    });
  });
}
