import 'telemetry_model.dart';

/// Represents a paginated response containing a list of telemetry records.
class TelemetryListResponse {
  final List<TelemetryModel> data;
  final TelemetryListMeta meta;

  const TelemetryListResponse({
    required this.data,
    required this.meta,
  });

  factory TelemetryListResponse.fromJson(Map<String, dynamic> json) {
    return TelemetryListResponse(
      data: (json['data'] as List)
          .map((item) => TelemetryModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: TelemetryListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Metadata for the paginated telemetry list response.
class TelemetryListMeta {
  final int totalCount;
  final int currentPage;
  final int limit;
  final int totalPages;

  const TelemetryListMeta({
    required this.totalCount,
    required this.currentPage,
    required this.limit,
    required this.totalPages,
  });

  factory TelemetryListMeta.fromJson(Map<String, dynamic> json) {
    return TelemetryListMeta(
      totalCount: json['total_count'] as int,
      currentPage: json['current_page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
