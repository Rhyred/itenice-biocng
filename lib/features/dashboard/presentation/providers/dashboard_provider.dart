import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';

/// A provider that holds the currently selected project for the dashboard.
final selectedProjectProvider = StateProvider<ProjectModel?>((ref) => null);

/// Data structure for the Dashboard summary.
class DashboardSummary {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final List<AlertModel> recentAlerts;
  final List<TelemetryModel> latestTelemetry;
  final int criticalAlerts;
  final int warningAlerts;
  final int activeAlerts;

  DashboardSummary({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.recentAlerts,
    required this.latestTelemetry,
    required this.criticalAlerts,
    required this.warningAlerts,
    required this.activeAlerts,
  });
}

/// A provider that aggregates data for the dashboard based on the selected project.
final dashboardDataProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final project = ref.watch(selectedProjectProvider);
  if (project == null) {
    throw Exception('No project selected');
  }

  if (AppConfig.isDemoMode) {
    final demoState = ref.watch(demoDataControllerProvider);
    
    int activeCount = demoState.alerts.where((a) => a.status.toUpperCase() == 'ACTIVE').length;
    int criticalCount = demoState.alerts.where((a) => a.status.toUpperCase() == 'ACTIVE' && a.severity.toUpperCase() == 'CRITICAL').length;
    int warningCount = demoState.alerts.where((a) => a.status.toUpperCase() == 'ACTIVE' && a.severity.toUpperCase() == 'WARNING').length;

    return DashboardSummary(
      totalDevices: demoState.devices.length,
      onlineDevices: demoState.devices.where((d) => d.status.toUpperCase() == 'ONLINE').length,
      offlineDevices: demoState.devices.where((d) => d.status.toUpperCase() == 'OFFLINE').length,
      recentAlerts: demoState.alerts,
      latestTelemetry: demoState.telemetryHistory.isNotEmpty ? [demoState.telemetryHistory.first] : [],
      criticalAlerts: criticalCount,
      warningAlerts: warningCount,
      activeAlerts: activeCount,
    );
  }

  final apiService = ref.read(apiServiceProvider);
// ... rest

  // 1. Fetch Devices for the project
  final devicesResponse = await ref.watch(deviceListProvider(project.id).future);
  final devices = devicesResponse.data;

  // Calculate device status counts
  final totalDevices = devices.length;
  final onlineDevices = devices.where((d) => d.status.toUpperCase() == 'ONLINE').length;
  final offlineDevices = devices.where((d) => d.status.toUpperCase() == 'OFFLINE').length;

  // 2. Fetch Alerts for the devices (MVP: Aggregate from top devices or first few)
  // Since GET /alerts?project_id is not supported, we fetch alerts for each device.
  // To avoid too many requests, we limit to the first 5 devices for summary or 
  // fetch recent alerts across the project if possible.
  // For MVP, we'll try to fetch alerts for each device in parallel (limited).
  
  List<AlertModel> allRecentAlerts = [];
  int criticalCount = 0;
  int warningCount = 0;
  int activeCount = 0;

  // We only fetch for the first few devices to keep it fast for MVP summary
  final devicesToFetch = devices.take(10).toList();
  
  final alertFutures = devicesToFetch.map((device) => apiService.getAlerts(deviceId: device.id, limit: 5));
  final alertResponses = await Future.wait(alertFutures);

  for (final response in alertResponses) {
    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      final alerts = data.map((json) => AlertModel.fromJson(json as Map<String, dynamic>)).toList();
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

  // 3. Fetch Latest Telemetry
  // We'll fetch the latest telemetry for each device (first few)
  List<TelemetryModel> latestTelemetry = [];
  final now = DateTime.now();
  final startTime = now.subtract(const Duration(hours: 24));

  final telemetryFutures = devicesToFetch.map((device) => apiService.getTelemetry(
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
        latestTelemetry.add(TelemetryModel.fromJson(data.first as Map<String, dynamic>));
      }
    }
  }

  return DashboardSummary(
    totalDevices: totalDevices,
    onlineDevices: onlineDevices,
    offlineDevices: offlineDevices,
    recentAlerts: allRecentAlerts..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    latestTelemetry: latestTelemetry,
    criticalAlerts: criticalCount,
    warningAlerts: warningCount,
    activeAlerts: activeCount,
  );
});
