import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../../../../core/mqtt/mqtt_provider.dart';
import '../../../../core/mqtt/mqtt_state.dart';

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
    return Card(
      elevation: 4,
      shadowColor: Colors.green.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.green.shade50],
          ),
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
                    'System Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.hub_outlined, color: Colors.green.shade700),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatusItem(label: 'Total', value: total.toString(), color: Colors.blue.shade700),
                  _StatusItem(label: 'Online', value: online.toString(), color: Colors.green.shade700),
                  _StatusItem(label: 'Offline', value: offline.toString(), color: Colors.red.shade700),
                ],
              ),
            ],
          ),
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
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
    final mqttState = ref.watch(mqttProvider);
    
    // Combine baseline REST data with real-time MQTT data
    final displayedTelemetry = telemetry.map((restTelemetry) {
      final deviceId = restTelemetry.deviceId;
      final component = restTelemetry.component ?? 'default'; // Fallback if no component
      final key = '$deviceId:$component';
      
      // Overlay with MQTT data if available
      final mqttTelemetry = mqttState.realtimeTelemetry[key];
      return mqttTelemetry ?? restTelemetry;
    }).toList();

    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Realtime Telemetry',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.sensors, color: Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 20),
            if (displayedTelemetry.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No recent telemetry available.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...displayedTelemetry.take(1).map((t) {
                final deviceId = t.deviceId;
                final component = t.component ?? 'default';
                final key = '$deviceId:$component';
                final isLive = mqttState.realtimeTelemetry.containsKey(key) && 
                               mqttState.connectionStatus == MqttConnectionStatus.connected;
                return _TelemetryGrid(telemetry: t, isLive: isLive);
              }),
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
            const Icon(Icons.developer_board, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Device: ${telemetry.deviceId ?? 'Unknown'}',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade600),
            ),
            if (isLive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
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
              'Last update: ${telemetry.timestamp.hour}:${telemetry.timestamp.minute.toString().padLeft(2, '0')}:${telemetry.timestamp.second.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: telemetry.metrics.entries.map((e) {
            return _MetricTile(
              label: e.key.replaceAll('_', ' ').toUpperCase(),
              value: '${e.value.value.toStringAsFixed(1)} ${e.value.unit}',
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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
    return Card(
      elevation: 4,
      shadowColor: Colors.orange.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.orange.shade50],
          ),
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
                    'Alerts Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AlertItem(label: 'Critical', value: critical.toString(), color: Colors.red.shade700),
                  _AlertItem(label: 'Warning', value: warning.toString(), color: Colors.orange.shade700),
                  _AlertItem(label: 'Active', value: active.toString(), color: Colors.blueGrey.shade700),
                ],
              ),
            ],
          ),
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
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
