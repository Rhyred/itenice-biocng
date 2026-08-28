import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../shared/models/alert_list_response.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';

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

/// Demo mode: Provider SINKRON — langsung reaktif tanpa loading loop
/// Setiap tick demo hanya rebuild widget, tidak re-fetch dari awal
final demoAlertsProvider =
    Provider.autoDispose.family<AlertListResponse, AlertParams>((ref, params) {
  final demoState = ref.watch(demoDataControllerProvider);

  var alerts = demoState.alerts;

  // Terapkan filter lokal (severity & status)
  if (params.severity != null) {
    alerts = alerts
        .where(
            (a) => a.severity.toUpperCase() == params.severity!.toUpperCase())
        .toList();
  }
  if (params.status != null) {
    alerts = alerts
        .where((a) => a.status.toUpperCase() == params.status!.toUpperCase())
        .toList();
  }

  return AlertListResponse(
    data: alerts,
    meta: AlertListMeta(
      totalCount: alerts.length,
      currentPage: 1,
      limit: 100,
      totalPages: 1,
    ),
  );
});

/// Production mode: AsyncNotifier yang fetch dari API
final alertsProvider =
    AsyncNotifierProvider.autoDispose.family<AlertsNotifier, AlertListResponse,
        AlertParams>(() {
  return AlertsNotifier();
});

class AlertsNotifier
    extends AutoDisposeFamilyAsyncNotifier<AlertListResponse, AlertParams> {
  @override
  FutureOr<AlertListResponse> build(AlertParams arg) async {
    return _fetch(page: 1);
  }

  Future<AlertListResponse> _fetch({required int page}) async {
    if (AppConfig.isDemoMode) {
      // Snapshot satu kali — TIDAK watch agar tidak loop
      final demoState = ref.read(demoDataControllerProvider);

      var alerts = demoState.alerts;
      if (arg.severity != null) {
        alerts = alerts
            .where((a) =>
                a.severity.toUpperCase() == arg.severity!.toUpperCase())
            .toList();
      }
      if (arg.status != null) {
        alerts = alerts
            .where(
                (a) => a.status.toUpperCase() == arg.status!.toUpperCase())
            .toList();
      }

      return AlertListResponse(
        data: alerts,
        meta: AlertListMeta(
          totalCount: alerts.length,
          currentPage: 1,
          limit: 20,
          totalPages: 1,
        ),
      );
    }

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

    if (currentData.meta.currentPage >= currentData.meta.totalPages) return;
    if (state.isLoading) return;

    state = const AsyncLoading<AlertListResponse>().copyWithPrevious(state);

    try {
      final nextPage =
          await _fetch(page: currentData.meta.currentPage + 1);

      state = AsyncData(AlertListResponse(
        data: [...currentData.data, ...nextPage.data],
        meta: nextPage.meta,
      ));
    } catch (e, st) {
      state = AsyncError<AlertListResponse>(e, st).copyWithPrevious(state);
    }
  }
}
