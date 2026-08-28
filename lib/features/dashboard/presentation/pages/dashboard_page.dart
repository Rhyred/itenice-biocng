import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/summary_cards.dart';
import '../../../devices/presentation/pages/device_list_page.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../telemetry/presentation/pages/telemetry_history_page.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../core/config/app_config.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);
    final summaryAsync = ref.watch(dashboardDataProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BioCNG by CoreSight')),
        body: const Center(child: Text('No project selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BioCNG by CoreSight',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Monitoring System',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (AppConfig.isDemoMode)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LIVE DEMO',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardDataProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardDataProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProjectHeader(project: project),
              const SizedBox(height: 16),
              summaryAsync.when(
                data: (summary) => Column(
                  children: [
                    StatusSummaryCard(
                      total: summary.totalDevices,
                      online: summary.onlineDevices,
                      offline: summary.offlineDevices,
                    ),
                    const SizedBox(height: 16),
                    TelemetrySummaryCard(telemetry: summary.latestTelemetry),
                    const SizedBox(height: 16),
                    AlertSummaryCard(
                      critical: summary.criticalAlerts,
                      warning: summary.warningAlerts,
                      active: summary.activeAlerts,
                    ),
                  ],
                ),
// ... rest
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => _ErrorSection(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(dashboardDataProvider),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _QuickActions(project: project),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final ProjectModel project;

  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(project.location, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorSection({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Failed to load summary data',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  final ProjectModel project;

  const _QuickActions({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.developer_board,
          label: 'View Devices',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceListPage(projectId: project.id, projectName: project.name),
            ),
          ),
        ),
        _ActionTile(
          icon: Icons.history,
          label: 'View Telemetry History',
          onTap: () {
            // Use the summary to find a device ID if possible, or just go to devices
            final summary = ref.read(dashboardDataProvider).value;
            if (summary != null && summary.totalDevices > 0) {
              // For MVP, we'll navigate to the first available device's telemetry
              // In a real app, this might go to a project-wide telemetry view
              final deviceId = summary.latestTelemetry.isNotEmpty 
                  ? summary.latestTelemetry.first.deviceId 
                  : null;
              
              if (deviceId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelemetryHistoryPage(deviceId: deviceId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a device from the list.')),
                );
              }
            }
          },
        ),
        _ActionTile(
          icon: Icons.notifications,
          label: 'View Alerts',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AlertsPage(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
