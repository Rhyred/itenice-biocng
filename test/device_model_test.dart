import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/shared/models/device_model.dart';
import 'package:itenice_bio_cng/shared/models/device_list_response.dart';

void main() {
  group('DeviceModel', () {
    test('fromJson should create a valid DeviceModel', () {
      final json = {
        'id': 'uuid-1',
        'name': 'Digester 1',
        'type': 'ESP32',
        'status': 'ONLINE',
        'firmware': '1.0.0',
        'last_seen': '2026-08-25T10:00:00Z',
      };

      final device = DeviceModel.fromJson(json);

      expect(device.id, 'uuid-1');
      expect(device.name, 'Digester 1');
      expect(device.type, 'ESP32');
      expect(device.status, 'ONLINE');
      expect(device.firmware, '1.0.0');
      expect(device.lastSeen, isA<DateTime>());
    });

    test('toJson should return a valid Map', () {
      final device = DeviceModel(
        id: 'uuid-1',
        name: 'Digester 1',
        type: 'ESP32',
        status: 'ONLINE',
        firmware: '1.0.0',
        lastSeen: DateTime.parse('2026-08-25T10:00:00Z'),
      );

      final json = device.toJson();

      expect(json['id'], 'uuid-1');
      expect(json['name'], 'Digester 1');
      expect(json['type'], 'ESP32');
      expect(json['status'], 'ONLINE');
      expect(json['firmware'], '1.0.0');
      expect(json['last_seen'], '2026-08-25T10:00:00.000Z');
    });
  });

  group('DeviceListResponse', () {
    test('fromJson should create a valid DeviceListResponse', () {
      final json = {
        'data': [
          {
            'id': 'uuid-1',
            'name': 'Digester 1',
            'type': 'ESP32',
            'status': 'ONLINE',
            'firmware': '1.0.0',
            'last_seen': '2026-08-25T10:00:00Z',
          }
        ],
        'meta': {
          'total_count': 1,
          'current_page': 1,
          'limit': 20,
          'total_pages': 1,
        }
      };

      final response = DeviceListResponse.fromJson(json);

      expect(response.data.length, 1);
      expect(response.data[0].id, 'uuid-1');
      expect(response.meta.totalCount, 1);
    });
  });
}
