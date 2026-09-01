import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';
import '../../../../core/mqtt/mqtt_provider.dart';

/// A provider that holds the currently selected project for the dashboard.
final selectedProjectProvider = StateProvider<ProjectModel?>((ref) => null);

/// Data structure for the Dashboard summary.
class DashboardSummary {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final List<AlertModel> recentAlerts;
  final List<TelemetryModel> latestTelemetry;
  final List<TelemetryModel> telemetryHistory;
  final int criticalAlerts;
  final int warningAlerts;
  final int activeAlerts;

  DashboardSummary({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.recentAlerts,
    required this.latestTelemetry,
    required this.telemetryHistory,
    required this.criticalAlerts,
    required this.warningAlerts,
    required this.activeAlerts,
  });
}

/// Demo mode: Provider sinkron — langsung baca dari demoState TANPA FutureProvider
final demoDashboardProvider = Provider.autoDispose<DashboardSummary>((ref) {
  final project = ref.watch(selectedProjectProvider);
  if (project == null) {
    return DashboardSummary(
      totalDevices: 0,
      onlineDevices: 0,
      offlineDevices: 0,
      recentAlerts: [],
      latestTelemetry: [],
      telemetryHistory: [],
      criticalAlerts: 0,
      warningAlerts: 0,
      activeAlerts: 0,
    );
  }

  final demoState = ref.watch(demoDataControllerProvider);

  final activeCount = demoState.alerts
      .where((a) => a.status.toUpperCase() == 'ACTIVE')
      .length;
  final criticalCount = demoState.alerts
      .where((a) =>
          a.status.toUpperCase() == 'ACTIVE' &&
          a.severity.toUpperCase() == 'CRITICAL')
      .length;
  final warningCount = demoState.alerts
      .where((a) =>
          a.status.toUpperCase() == 'ACTIVE' &&
          a.severity.toUpperCase() == 'WARNING')
      .length;

  return DashboardSummary(
    totalDevices: demoState.devices.length,
    onlineDevices: demoState.devices
        .where((d) => d.status.toUpperCase() == 'ONLINE')
        .length,
    offlineDevices: demoState.devices
        .where((d) => d.status.toUpperCase() == 'OFFLINE')
        .length,
    recentAlerts: demoState.alerts,
    latestTelemetry: demoState.telemetryHistory.isNotEmpty
        ? [demoState.telemetryHistory.first]
        : [],
    telemetryHistory: demoState.telemetryHistory,
    criticalAlerts: criticalCount,
    warningAlerts: warningCount,
    activeAlerts: activeCount,
  );
});

/// Production mode: FutureProvider yang fetch data dashboard
final dashboardDataProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final auth = ref.watch(authProvider);

  // Local Monitoring Mode: pure MQTT realtime data, no protected REST API calls
  if (auth.isLocalMonitoring) {
    final mqttState = ref.watch(mqttProvider);
    final telemetryList = mqttState.realtimeTelemetry.values.toList();

    int onlineCount = 0;
    int offlineCount = 0;
    for (final status in mqttState.deviceStatus.values) {
      if (status.toLowerCase() == 'online') {
        onlineCount++;
      } else if (status.toLowerCase() == 'offline') {
        offlineCount++;
      }
    }
    final totalDevs = mqttState.deviceStatus.isNotEmpty
        ? mqttState.deviceStatus.length
        : (telemetryList.isNotEmpty ? telemetryList.map((e) => e.deviceId).toSet().length : 1);

    final eventAlerts = mqttState.realtimeEvents.values.map((t) {
      final devId = t.deviceId ?? 'device';
      return AlertModel(
        id: '${devId}_${t.timestamp.millisecondsSinceEpoch}',
        deviceId: devId,
        component: t.component ?? 'System',
        severity: 'WARNING',
        message: 'Realtime event from $devId',
        status: 'ACTIVE',
        timestamp: t.timestamp,
      );
    }).toList();

    return DashboardSummary(
      totalDevices: totalDevs,
      onlineDevices: onlineCount,
      offlineDevices: offlineCount,
      recentAlerts: eventAlerts,
      latestTelemetry: telemetryList,
      telemetryHistory: telemetryList,
      criticalAlerts: 0,
      warningAlerts: eventAlerts.length,
      activeAlerts: eventAlerts.length,
    );
  }

  final project = ref.watch(selectedProjectProvider);
  if (project == null) {
    throw Exception('No project selected');
  }

  // Demo mode: delegasikan ke provider sinkron
  if (AppConfig.isDemoMode) {
    final demoState = ref.read(demoDataControllerProvider);

    final activeCount = demoState.alerts
        .where((a) => a.status.toUpperCase() == 'ACTIVE')
        .length;
    final criticalCount = demoState.alerts
        .where((a) =>
            a.status.toUpperCase() == 'ACTIVE' &&
            a.severity.toUpperCase() == 'CRITICAL')
        .length;
    final warningCount = demoState.alerts
        .where((a) =>
            a.status.toUpperCase() == 'ACTIVE' &&
            a.severity.toUpperCase() == 'WARNING')
        .length;

    return DashboardSummary(
      totalDevices: demoState.devices.length,
      onlineDevices: demoState.devices
          .where((d) => d.status.toUpperCase() == 'ONLINE')
          .length,
      offlineDevices: demoState.devices
          .where((d) => d.status.toUpperCase() == 'OFFLINE')
          .length,
      recentAlerts: demoState.alerts,
      latestTelemetry: demoState.telemetryHistory.isNotEmpty
          ? [demoState.telemetryHistory.first]
          : [],
      telemetryHistory: demoState.telemetryHistory,
      criticalAlerts: criticalCount,
      warningAlerts: warningCount,
      activeAlerts: activeCount,
    );
  }

  // ── Production API path ────────────────────────────────────────────────────
  final apiService = ref.read(apiServiceProvider);

  final devicesResponse =
      await ref.watch(deviceListProvider(project.id).future);
  final devices = devicesResponse.data;

  final totalDevices = devices.length;
  final onlineDevices =
      devices.where((d) => d.status.toUpperCase() == 'ONLINE').length;
  final offlineDevices =
      devices.where((d) => d.status.toUpperCase() == 'OFFLINE').length;

  List<AlertModel> allRecentAlerts = [];
  int criticalCount = 0;
  int warningCount = 0;
  int activeCount = 0;

  final devicesToFetch = devices.take(10).toList();

  final alertFutures = devicesToFetch
      .map((device) => apiService.getAlerts(deviceId: device.id, limit: 5));
  final alertResponses = await Future.wait(alertFutures);

  for (final response in alertResponses) {
    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      final alerts = data
          .map((json) =>
              AlertModel.fromJson(json as Map<String, dynamic>))
          .toList();
      allRecentAlerts.addAll(alerts);

      for (final alert in alerts) {
        if (alert.status.toUpperCase() == 'ACTIVE') {
          activeCount++;
          if (alert.severity.toUpperCase() == 'CRITICAL') {
            criticalCount++;
          } else if (alert.severity.toUpperCase() == 'WARNING') {
            warningCount++;
          }
        }
      }
    }
  }

  List<TelemetryModel> latestTelemetry = [];
  final now = DateTime.now();
  final startTime = now.subtract(const Duration(hours: 24));

  final telemetryFutures = devicesToFetch.map((device) =>
      apiService.getTelemetry(
        deviceId: device.id,
        startTime: startTime,
        endTime: now,
        limit: 1,
      ));

  final telemetryResponses = await Future.wait(telemetryFutures);

  for (final response in telemetryResponses) {
    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      if (data.isNotEmpty) {
        latestTelemetry.add(
            TelemetryModel.fromJson(data.first as Map<String, dynamic>));
      }
    }
  }

  // Fetch telemetry history for the main chart
  List<TelemetryModel> telemetryHistory = [];
  if (devicesToFetch.isNotEmpty) {
    final historyResponse = await apiService.getTelemetry(
      deviceId: devicesToFetch.first.id,
      startTime: startTime,
      endTime: now,
      limit: 50,
    );
    if (historyResponse.statusCode == 200) {
      final data = historyResponse.data['data'] as List;
      telemetryHistory = data
          .map((json) => TelemetryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  return DashboardSummary(
    totalDevices: totalDevices,
    onlineDevices: onlineDevices,
    offlineDevices: offlineDevices,
    recentAlerts:
        allRecentAlerts..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    latestTelemetry: latestTelemetry,
    telemetryHistory: telemetryHistory,
    criticalAlerts: criticalCount,
    warningAlerts: warningCount,
    activeAlerts: activeCount,
  );
});
