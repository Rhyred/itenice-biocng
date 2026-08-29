import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/device_provider.dart';
import '../../../../shared/models/device_model.dart';
import 'device_detail_page.dart';
import '../../../../core/widgets/sub_header.dart';

/// A page displaying the list of devices for a specific project.
class DeviceListPage extends ConsumerWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);

    if (project == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final devicesAsync = ref.watch(deviceListProvider(project.id));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const SubHeader(title: 'Nodes'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(deviceListProvider(project.id).future),
        child: devicesAsync.when(
            data: (response) => response.data.isEmpty
                ? _EmptyState(onRetry: () => ref.invalidate(deviceListProvider(project.id)))
                : _DeviceList(devices: response.data),
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (err, stack) => _ErrorState(
              error: err.toString(),
              onRetry: () => ref.invalidate(deviceListProvider(project.id)),
            ),
        ),
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  final List<DeviceModel> devices;

  const _DeviceList({required this.devices});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
      itemCount: devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = devices[index];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(device.status).withValues(alpha: 0.1),
              child: Icon(
                Icons.memory_rounded,
                color: _getStatusColor(device.status),
              ),
            ),
            title: Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Type: ${device.type}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(device.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(device.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (device.lastSeen != null)
                      Expanded(
                        child: Text(
                          'LAST SEEN: ${_formatDate(device.lastSeen!)}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
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
    switch (status.toUpperCase()) {
      case 'ONLINE':
      case 'NORMAL':
        return AppTheme.statusOptimal;
      case 'OFFLINE':
      case 'CRITICAL':
        return AppTheme.statusCritical;
      default:
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
