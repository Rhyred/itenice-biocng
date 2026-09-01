import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../../../../shared/models/device_model.dart';
import 'package:itenice_bio_cng/features/telemetry/presentation/pages/telemetry_history_page.dart';
import 'package:itenice_bio_cng/features/alerts/presentation/pages/alerts_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/mqtt/mqtt_provider.dart';
import '../../../../core/mqtt/mqtt_state.dart';

/// A page displaying the metadata details of a device.
class DeviceDetailPage extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailPage({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceDetailProvider(deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Perangkat'),
        actions: [
          if (AppConfig.isDemoMode)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: AppTheme.statusOptimal, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'DEMO',
                      style: TextStyle(
                        color: AppTheme.statusOptimal,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: deviceAsync.when(
        data: (device) => _DeviceDetailView(device: device),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(
          error: err.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(deviceId)),
        ),
      ),
    );
  }
}

class _DeviceDetailView extends ConsumerWidget {
  final DeviceModel device;

  const _DeviceDetailView({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttState = ref.watch(mqttProvider);
    
    // Override status with MQTT realtime status if available
    final realtimeStatus = mqttState.deviceStatus[device.id];
    final displayStatus = realtimeStatus ?? device.status;

    // Find realtime telemetry for this device
    final deviceTelemetryKeys = mqttState.realtimeTelemetry.keys.where((k) => k.startsWith('${device.id}:'));
    final hasRealtimeTelemetry = deviceTelemetryKeys.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(device: device),
          const SizedBox(height: 24),
          const Text(
            'Informasi Perangkat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _DetailCard(
            children: [
              _DetailItem(label: 'ID Perangkat', value: device.id),
              _DetailItem(label: 'Tipe', value: device.type),
              _DetailItem(label: 'Status', value: displayStatus, isStatus: true),
              _DetailItem(label: 'Firmware', value: device.firmware ?? 'Unknown'),
              _DetailItem(
                label: 'Terakhir Terlihat',
                value: device.lastSeen != null ? _formatDate(device.lastSeen!) : 'Tidak pernah',
              ),
              _DetailItem(
                label: 'Broker MQTT',
                value: mqttState.connectionStatus == MqttConnectionStatus.connected ? 'CONNECTED' : 'DISCONNECTED',
                isStatus: true,
              ),
            ],
          ),
          if (hasRealtimeTelemetry) ...[
            const SizedBox(height: 24),
            const Text(
              'Telemetri Real-time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ...deviceTelemetryKeys.map((key) {
              final t = mqttState.realtimeTelemetry[key]!;
              final isLive = mqttState.connectionStatus == MqttConnectionStatus.connected || AppConfig.isDemoMode;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Komponen: ${t.component ?? 'default'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.statusCritical, borderRadius: BorderRadius.circular(4)),
                            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Update: ${t.timestamp.hour}:${t.timestamp.minute.toString().padLeft(2, '0')}:${t.timestamp.second.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...t.metrics.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          Text('${e.value.value % 1 == 0 ? e.value.value.toInt() : e.value.value.toStringAsFixed(2)} ${e.value.unit}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          const Text(
            'Aksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelemetryHistoryPage(deviceId: device.id),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Lihat Riwayat Telemetri'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertsPage(deviceId: device.id),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Lihat Peringatan'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _HeaderSection extends StatelessWidget {
  final DeviceModel device;

  const _HeaderSection({required this.device});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.developer_board,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                device.type,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _DetailItem({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(value).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: _getStatusColor(value),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
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
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load device details',
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
      ),
    );
  }
}
