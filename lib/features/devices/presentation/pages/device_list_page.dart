import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../../../../shared/models/device_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/mqtt/mqtt_provider.dart';
import 'device_detail_page.dart';

/// A page displaying the list of devices for a specific project.
class DeviceListPage extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const DeviceListPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$projectName - Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(deviceListProvider(projectId).future),
        child: devicesAsync.when(
          data: (response) => response.data.isEmpty
              ? _EmptyState(onRetry: () => ref.invalidate(deviceListProvider(projectId)))
              : _DeviceList(devices: response.data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _ErrorState(
            error: err.toString(),
            onRetry: () => ref.invalidate(deviceListProvider(projectId)),
          ),
        ),
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  final List<DeviceModel> devices;

  const _DeviceList({required this.devices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttState = ref.watch(mqttProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = devices[index];
        final realtimeStatus = mqttState.deviceStatus[device.id];
        final displayStatus = realtimeStatus ?? device.status;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(displayStatus).withValues(alpha: 0.1),
              child: Icon(
                Icons.developer_board,
                color: _getStatusColor(displayStatus),
              ),
            ),
            title: Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipe: ${device.type}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(displayStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: _getStatusColor(displayStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (device.lastSeen != null)
                      Expanded(
                        child: Text(
                          'Update: ${_formatDate(device.lastSeen!)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailPage(deviceId: device.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'ONLINE' || s == 'CONNECTED') {
      return AppTheme.statusOptimal;
    } else if (s == 'OFFLINE' || s == 'DISCONNECTED') {
      return AppTheme.statusCritical;
    } else {
      return AppTheme.statusWarning;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.devices_other_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No devices found for this project.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Check Again'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load devices',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
