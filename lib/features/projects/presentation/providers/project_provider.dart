import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/config/runtime_config_store.dart';
import '../../../../shared/models/project_list_response.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// A provider that fetches the project list from the [ApiService].
final projectProvider = FutureProvider.autoDispose<ProjectListResponse>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.isLocalMonitoring) {
    final runtimeConfig = ref.watch(runtimeConfigProvider);
    return ProjectListResponse(
      data: [
        ProjectModel(
          id: runtimeConfig.effectiveSiteId,
          name: runtimeConfig.effectivePlantName,
          location: 'Local Emergency Broker',
        ),
      ],
      meta: const ProjectListMeta(
        totalCount: 1,
        currentPage: 1,
        limit: 10,
        totalPages: 1,
      ),
    );
  }

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
