import 'alert_model.dart';

/// Represents a paginated response containing a list of alerts.
class AlertListResponse {
  final List<AlertModel> data;
  final AlertListMeta meta;

  const AlertListResponse({
    required this.data,
    required this.meta,
  });

  factory AlertListResponse.fromJson(Map<String, dynamic> json) {
    return AlertListResponse(
      data: (json['data'] as List)
          .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: AlertListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Metadata for the paginated alert list response.
class AlertListMeta {
  final int totalCount;
  final int currentPage;
  final int limit;
  final int totalPages;

  const AlertListMeta({
    required this.totalCount,
    required this.currentPage,
    required this.limit,
    required this.totalPages,
  });

  factory AlertListMeta.fromJson(Map<String, dynamic> json) {
    return AlertListMeta(
      totalCount: json['total_count'] as int,
      currentPage: json['current_page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
