import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../shared/models/telemetry_list_response.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';

/// Parameters for the telemetry history query.
class TelemetryParams {
  final String deviceId;
  final DateTime startTime;
  final DateTime endTime;
  final String? component;

  const TelemetryParams({
    required this.deviceId,
    required this.startTime,
    required this.endTime,
    this.component,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetryParams &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          component == other.component;

  @override
  int get hashCode =>
      deviceId.hashCode ^ startTime.hashCode ^ endTime.hashCode ^ component.hashCode;
}

/// A provider that manages the state of historical telemetry data.
/// Uses [AsyncNotifier] to support "Load More" pagination while remaining
/// consistent with modern Riverpod patterns.
final telemetryProvider = AsyncNotifierProvider.autoDispose.family<TelemetryNotifier, TelemetryListResponse, TelemetryParams>(() {
  return TelemetryNotifier();
});

class TelemetryNotifier extends AutoDisposeFamilyAsyncNotifier<TelemetryListResponse, TelemetryParams> {
  @override
  FutureOr<TelemetryListResponse> build(TelemetryParams arg) async {
    return _fetch(page: 1);
  }

  Future<TelemetryListResponse> _fetch({required int page}) async {
    if (AppConfig.isDemoMode) {
      final demoState = ref.read(demoDataControllerProvider);
      return TelemetryListResponse(
        data: demoState.telemetryHistory,
        meta: TelemetryListMeta(
          totalCount: demoState.telemetryHistory.length,
          currentPage: 1,
          limit: 100,
          totalPages: 1,
        ),
      );
    }

    final apiService = ref.read(apiServiceProvider);
    
    // Validation: Do not call backend if start_time >= end_time
    if (arg.startTime.isAfter(arg.endTime) || arg.startTime.isAtSameMomentAs(arg.endTime)) {
      throw ArgumentError('Start time must be before end time');
    }

    final response = await apiService.getTelemetry(
      deviceId: arg.deviceId,
      startTime: arg.startTime,
      endTime: arg.endTime,
      component: arg.component,
      page: page,
    );
    
    if (response.statusCode == 200) {
      return TelemetryListResponse.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load telemetry: ${response.statusMessage}');
    }
  }

  /// Loads the next page of telemetry data and appends it to the current list.
  Future<void> loadMore() async {
    final currentData = state.value;
    if (currentData == null) return;
    
    // Stop if we already reached the last page
    if (currentData.meta.currentPage >= currentData.meta.totalPages) return;
    
    // Prevent multiple simultaneous loads
    if (state.isLoading) return;

    state = const AsyncLoading<TelemetryListResponse>().copyWithPrevious(state);
    
    try {
      final nextPage = await _fetch(page: currentData.meta.currentPage + 1);
      
      state = AsyncData(TelemetryListResponse(
        data: [...currentData.data, ...nextPage.data],
        meta: nextPage.meta,
      ));
    } catch (e, st) {
      state = AsyncError<TelemetryListResponse>(e, st).copyWithPrevious(state);
    }
  }
}
