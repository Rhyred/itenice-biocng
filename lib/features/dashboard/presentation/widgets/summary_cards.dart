import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../../../../core/mqtt/mqtt_provider.dart';
import '../../../../core/mqtt/mqtt_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';

class StatusSummaryCard extends StatelessWidget {
  final int total;
  final int online;
  final int offline;

  const StatusSummaryCard({
    super.key,
    required this.total,
    required this.online,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ikhtisar Sistem',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Icon(Icons.hub_outlined, color: AppTheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusItem(label: 'Total', value: total.toString(), color: AppTheme.textPrimary),
                _StatusItem(label: 'Online', value: online.toString(), color: AppTheme.statusOptimal),
                _StatusItem(label: 'Offline', value: offline.toString(), color: AppTheme.statusCritical),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ],
    );
  }
}

class TelemetrySummaryCard extends ConsumerWidget {
  final List<TelemetryModel> telemetry;

  const TelemetrySummaryCard({super.key, required this.telemetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (telemetry.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Text('Tidak ada data telemetri.', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    // Using the first device as the summary representative
    final baseT = telemetry.first;
    final deviceId = baseT.deviceId;
    final component = baseT.component ?? 'default';
    final key = '$deviceId:$component';

    // Watch only the specific realtime telemetry for this device:component
    final mqttT = ref.watch(mqttProvider.select((s) => s.realtimeTelemetry[key]));
    final isMqttConnected = ref.watch(mqttProvider.select((s) => s.connectionStatus == MqttConnectionStatus.connected));
    
    final displayedT = mqttT ?? baseT;
    final isLive = (mqttT != null && isMqttConnected) || AppConfig.isDemoMode;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Telemetri Real-time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Icon(Icons.sensors, color: AppTheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            _TelemetryGrid(telemetry: displayedT, isLive: isLive),
          ],
        ),
      ),
    );
  }
}

class _TelemetryGrid extends StatelessWidget {
  final TelemetryModel telemetry;
  final bool isLive;

  const _TelemetryGrid({required this.telemetry, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.developer_board, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Perangkat: ${telemetry.deviceId ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: AppTheme.textSecondary),
            ),
            if (isLive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.statusCritical,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              )
            ],
            const Spacer(),
            Text(
              'Update: ${_formatTime(telemetry.timestamp)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.8,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: telemetry.metrics.entries.map((e) {
            return _MetricTile(
              label: e.key.replaceAll('_', ' ').toUpperCase(),
              value: '${e.value.value % 1 == 0 ? e.value.value.toInt() : e.value.value.toStringAsFixed(1)} ${e.value.unit}',
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class AlertSummaryCard extends StatelessWidget {
  final int critical;
  final int warning;
  final int active;

  const AlertSummaryCard({
    super.key,
    required this.critical,
    required this.warning,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ringkasan Peringatan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Icon(Icons.warning_amber_rounded, color: AppTheme.statusWarning, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AlertItem(label: 'Kritis', value: critical.toString(), color: AppTheme.statusCritical),
                _AlertItem(label: 'Peringatan', value: warning.toString(), color: AppTheme.statusWarning),
                _AlertItem(label: 'Aktif', value: active.toString(), color: AppTheme.textPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AlertItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ],
    );
  }
}
