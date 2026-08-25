import 'package:flutter_test/flutter_test.dart';
import 'package:itenice_bio_cng/shared/models/project_model.dart';
import 'package:itenice_bio_cng/shared/models/project_list_response.dart';

void main() {
  group('ProjectModel', () {
    test('should parse JSON correctly', () {
      final json = {
        'id': 'uuid-1',
        'name': 'Bio-CNG Alpha',
        'location': 'Location A',
      };

      final project = ProjectModel.fromJson(json);

      expect(project.id, 'uuid-1');
      expect(project.name, 'Bio-CNG Alpha');
      expect(project.location, 'Location A');
    });

    test('should convert to JSON correctly', () {
      const project = ProjectModel(
        id: 'uuid-1',
        name: 'Bio-CNG Alpha',
        location: 'Location A',
      );

      final json = project.toJson();

      expect(json['id'], 'uuid-1');
      expect(json['name'], 'Bio-CNG Alpha');
      expect(json['location'], 'Location A');
    });
  });

  group('ProjectListResponse', () {
    test('should parse paginated response JSON correctly', () {
      final json = {
        'data': [
          {
            'id': 'uuid-1',
            'name': 'Bio-CNG Alpha',
            'location': 'Location A',
          }
        ],
        'meta': {
          'total_count': 1,
          'current_page': 1,
          'limit': 20,
          'total_pages': 1,
        }
      };

      final response = ProjectListResponse.fromJson(json);

      expect(response.data.length, 1);
      expect(response.data[0].name, 'Bio-CNG Alpha');
      expect(response.meta.totalCount, 1);
      expect(response.meta.totalPages, 1);
    });
  });
}
