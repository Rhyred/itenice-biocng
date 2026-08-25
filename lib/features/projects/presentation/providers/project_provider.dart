import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../shared/models/project_list_response.dart';

/// A provider that fetches the project list from the [ApiService].
final projectProvider = FutureProvider.autoDispose<ProjectListResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getProjects();
  
  if (response.statusCode == 200) {
    return ProjectListResponse.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load projects: ${response.statusMessage}');
  }
});
