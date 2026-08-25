import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../shared/models/alert_list_response.dart';

/// Parameters for the alerts query.
class AlertParams {
  final String? severity;
  final String? status;
  final String? deviceId;

  const AlertParams({
    this.severity,
    this.status,
    this.deviceId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertParams &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          status == other.status &&
          deviceId == other.deviceId;

  @override
  int get hashCode => severity.hashCode ^ status.hashCode ^ deviceId.hashCode;
}

/// A provider that manages the state of historical alerts data.
/// Uses [AsyncNotifier] to support "Load More" pagination.
final alertsProvider = AsyncNotifierProvider.autoDispose.family<AlertsNotifier, AlertListResponse, AlertParams>(() {
  return AlertsNotifier();
});

class AlertsNotifier extends AutoDisposeFamilyAsyncNotifier<AlertListResponse, AlertParams> {
  @override
  FutureOr<AlertListResponse> build(AlertParams arg) async {
    return _fetch(page: 1);
  }

  Future<AlertListResponse> _fetch({required int page}) async {
    final apiService = ref.read(apiServiceProvider);
    
    final response = await apiService.getAlerts(
      severity: arg.severity,
      status: arg.status,
      deviceId: arg.deviceId,
      page: page,
    );
    
    if (response.statusCode == 200) {
      return AlertListResponse.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load alerts: ${response.statusMessage}');
    }
  }

  /// Loads the next page of alerts and appends it to the current list.
  Future<void> loadMore() async {
    final currentData = state.value;
    if (currentData == null) return;
    
    // Stop if we already reached the last page
    if (currentData.meta.currentPage >= currentData.meta.totalPages) return;
    
    // Prevent multiple simultaneous loads
    if (state.isLoading) return;

    state = const AsyncLoading<AlertListResponse>().copyWithPrevious(state);
    
    try {
      final nextPage = await _fetch(page: currentData.meta.currentPage + 1);
      
      state = AsyncData(AlertListResponse(
        data: [...currentData.data, ...nextPage.data],
        meta: nextPage.meta,
      ));
    } catch (e, st) {
      state = AsyncError<AlertListResponse>(e, st).copyWithPrevious(state);
    }
  }
}
