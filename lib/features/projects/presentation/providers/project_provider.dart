import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../shared/models/project_list_response.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';

/// A provider that fetches the project list from the [ApiService].
final projectProvider = FutureProvider.autoDispose<ProjectListResponse>((ref) async {
  if (AppConfig.isDemoMode) {
    return const ProjectListResponse(
      data: [
        ProjectModel(
          id: DemoDataController.demoProjectId,
          name: 'Bio-CNG Plant Alpha',
          location: 'Industrial Zone A',
        ),
      ],
      meta: ProjectListMeta(
        totalCount: 1,
        currentPage: 1,
        limit: 10,
        totalPages: 1,
      ),
    );
  }

  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getProjects();
  
  if (response.statusCode == 200) {
    return ProjectListResponse.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load projects: ${response.statusMessage}');
  }
});
