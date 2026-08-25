import 'device_model.dart';

/// Represents a paginated response containing a list of devices.
class DeviceListResponse {
  final List<DeviceModel> data;
  final DeviceListMeta meta;

  const DeviceListResponse({
    required this.data,
    required this.meta,
  });

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceListResponse(
      data: (json['data'] as List)
          .map((item) => DeviceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: DeviceListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Metadata for the paginated device list response.
class DeviceListMeta {
  final int totalCount;
  final int currentPage;
  final int limit;
  final int totalPages;

  const DeviceListMeta({
    required this.totalCount,
    required this.currentPage,
    required this.limit,
    required this.totalPages,
  });

  factory DeviceListMeta.fromJson(Map<String, dynamic> json) {
    return DeviceListMeta(
      totalCount: json['total_count'] as int,
      currentPage: json['current_page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
