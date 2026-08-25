import 'package:flutter/material.dart';
import '../../../../shared/models/telemetry_model.dart';

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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusItem(label: 'Total', value: total.toString(), color: Colors.blue),
                _StatusItem(label: 'Online', value: online.toString(), color: Colors.green),
                _StatusItem(label: 'Offline', value: offline.toString(), color: Colors.red),
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
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class TelemetrySummaryCard extends StatelessWidget {
  final List<TelemetryModel> telemetry;

  const TelemetrySummaryCard({super.key, required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Telemetry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (telemetry.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No recent telemetry available.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...telemetry.take(3).map((t) => _TelemetryRow(telemetry: t)),
          ],
        ),
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final TelemetryModel telemetry;

  const _TelemetryRow({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device: ${telemetry.deviceId ?? 'Unknown'}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey),
          ),
          Wrap(
            spacing: 12,
            children: telemetry.metrics.entries.map((e) {
              return Text('${e.key}: ${e.value.value}${e.value.unit}');
            }).toList(),
          ),
          const Divider(),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alerts Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AlertItem(label: 'Critical', value: critical.toString(), color: Colors.red),
                _AlertItem(label: 'Warning', value: warning.toString(), color: Colors.orange),
                _AlertItem(label: 'Active', value: active.toString(), color: Colors.blueGrey),
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
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
