import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/shared/models/alert_list_response.dart';

void main() {
  group('AlertListResponse', () {
    test('fromJson should create a valid AlertListResponse', () {
      final json = {
        'data': [
          {
            'id': 'alert-1',
            'device_id': 'device-1',
            'component': 'digester',
            'severity': 'CRITICAL',
            'status': 'ACTIVE',
            'message': 'High pressure',
            'timestamp': '2023-10-27T10:00:00Z',
          }
        ],
        'meta': {
          'total_count': 1,
          'current_page': 1,
          'limit': 20,
          'total_pages': 1,
        }
      };

      final response = AlertListResponse.fromJson(json);

      expect(response.data.length, 1);
      expect(response.data[0].id, 'alert-1');
      expect(response.meta.totalCount, 1);
      expect(response.meta.totalPages, 1);
    });
  });
}
