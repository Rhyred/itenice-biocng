import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/shared/models/telemetry_model.dart';

void main() {
  group('TelemetryModel', () {
    test('should parse from JSON with dynamic metrics', () {
      final json = {
        'timestamp': '2023-10-27T10:00:00Z',
        'device_id': 'device-1',
        'component': 'sensor-a',
        'status': 'healthy',
        'metrics': {
          'temp': {'v': 25.5, 'u': 'C'},
          'humidity': {'v': 60.0, 'u': '%'},
        },
      };

      final model = TelemetryModel.fromJson(json);

      expect(model.timestamp, DateTime.parse('2023-10-27T10:00:00Z'));
      expect(model.deviceId, 'device-1');
      expect(model.component, 'sensor-a');
      expect(model.status, 'healthy');
      expect(model.metrics['temp']?.value, 25.5);
      expect(model.metrics['temp']?.unit, 'C');
      expect(model.metrics['humidity']?.value, 60.0);
      expect(model.metrics['humidity']?.unit, '%');
    });

    test('should override deviceId and component if provided in fromJson', () {
      final json = <String, dynamic>{
        'timestamp': '2023-10-27T10:00:00Z',
        'metrics': <String, dynamic>{},
      };

      final model = TelemetryModel.fromJson(
        json,
        deviceId: 'overridden-id',
        component: 'overridden-comp',
      );

      expect(model.deviceId, 'overridden-id');
      expect(model.component, 'overridden-comp');
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.parse('2023-10-27T10:00:00Z');
      final model = TelemetryModel(
        timestamp: timestamp,
        deviceId: 'device-1',
        component: 'sensor-a',
        status: 'healthy',
        metrics: {
          'temp': MetricValue(value: 25.5, unit: 'C'),
        },
      );

      final json = model.toJson();

      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['device_id'], 'device-1');
      expect(json['component'], 'sensor-a');
      expect(json['status'], 'healthy');
      expect(json['metrics']['temp']['v'], 25.5);
      expect(json['metrics']['temp']['u'], 'C');
    });
  });
}
