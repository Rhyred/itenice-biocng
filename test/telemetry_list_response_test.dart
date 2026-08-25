import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/shared/models/telemetry_list_response.dart';

void main() {
  group('TelemetryListResponse', () {
    test('should parse from paginated JSON', () {
      final json = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'timestamp': '2023-10-27T10:00:00Z',
            'metrics': <String, dynamic>{
              'temp': <String, dynamic>{'v': 25.5, 'u': 'C'}
            },
          },
          <String, dynamic>{
            'timestamp': '2023-10-27T10:05:00Z',
            'metrics': <String, dynamic>{
              'temp': <String, dynamic>{'v': 26.0, 'u': 'C'}
            },
          }
        ],
        'meta': <String, dynamic>{
          'total_count': 100,
          'current_page': 1,
          'limit': 2,
          'total_pages': 50,
        }
      };

      final response = TelemetryListResponse.fromJson(json);

      expect(response.data.length, 2);
      expect(response.data[0].timestamp, DateTime.parse('2023-10-27T10:00:00Z'));
      expect(response.meta.totalCount, 100);
      expect(response.meta.currentPage, 1);
      expect(response.meta.totalPages, 50);
    });
  });
}
