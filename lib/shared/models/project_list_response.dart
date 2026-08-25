import 'project_model.dart';

/// Represents a paginated response containing a list of projects.
class ProjectListResponse {
  final List<ProjectModel> data;
  final ProjectListMeta meta;

  const ProjectListResponse({
    required this.data,
    required this.meta,
  });

  factory ProjectListResponse.fromJson(Map<String, dynamic> json) {
    return ProjectListResponse(
      data: (json['data'] as List)
          .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ProjectListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Metadata for the paginated project list response.
class ProjectListMeta {
  final int totalCount;
  final int currentPage;
  final int limit;
  final int totalPages;

  const ProjectListMeta({
    required this.totalCount,
    required this.currentPage,
    required this.limit,
    required this.totalPages,
  });

  factory ProjectListMeta.fromJson(Map<String, dynamic> json) {
    return ProjectListMeta(
      totalCount: json['total_count'] as int,
      currentPage: json['current_page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
