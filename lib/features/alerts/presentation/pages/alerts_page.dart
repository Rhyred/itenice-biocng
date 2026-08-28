import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/alert_list_response.dart';
import '../providers/alerts_provider.dart';
import '../../../../core/config/app_config.dart';

class AlertsPage extends ConsumerStatefulWidget {
  final String? deviceId;

  const AlertsPage({
    super.key,
    this.deviceId,
  });

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  String? _severity;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final params = AlertParams(
      deviceId: widget.deviceId,
      severity: _severity,
      status: _status,
    );

    final alertsAsync = ref.watch(alertsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts History'),
        actions: [
          if (AppConfig.isDemoMode)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'DEMO',
                      style: TextStyle(
                        color: Colors.green,
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
      body: Column(
        children: [
          _FilterSection(
            selectedSeverity: _severity,
            selectedStatus: _status,
            onSeverityChanged: (val) => setState(() => _severity = val),
            onStatusChanged: (val) => setState(() => _status = val),
          ),
          Expanded(
            child: alertsAsync.when(
              data: (response) {
                if (response.data.isEmpty) {
                  return const Center(child: Text('No alerts found.'));
                }
                return _AlertList(
                  response: response,
                  onLoadMore: () => ref.read(alertsProvider(params).notifier).loadMore(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _ErrorState(
                error: err.toString(),
                onRetry: () => ref.invalidate(alertsProvider(params)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String? selectedSeverity;
  final String? selectedStatus;
  final ValueChanged<String?> onSeverityChanged;
  final ValueChanged<String?> onStatusChanged;

  const _FilterSection({
    required this.selectedSeverity,
    required this.selectedStatus,
    required this.onSeverityChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Severity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedSeverity == null,
                  onSelected: (_) => onSeverityChanged(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'CRITICAL',
                  isSelected: selectedSeverity == 'CRITICAL',
                  onSelected: (_) => onSeverityChanged('CRITICAL'),
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'WARNING',
                  isSelected: selectedSeverity == 'WARNING',
                  onSelected: (_) => onSeverityChanged('WARNING'),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'INFO',
                  isSelected: selectedSeverity == 'INFO',
                  onSelected: (_) => onSeverityChanged('INFO'),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: selectedStatus == null,
                onSelected: (_) => onStatusChanged(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'ACTIVE',
                isSelected: selectedStatus == 'ACTIVE',
                onSelected: (_) => onStatusChanged('ACTIVE'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'RESOLVED',
                isSelected: selectedStatus == 'RESOLVED',
                onSelected: (_) => onStatusChanged('RESOLVED'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: color?.withValues(alpha: 0.2) ?? Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? Theme.of(context).primaryColor) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  final AlertListResponse response;
  final VoidCallback onLoadMore;

  const _AlertList({required this.response, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: response.data.length + (response.meta.currentPage < response.meta.totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == response.data.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: onLoadMore,
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final alert = response.data[index];
        return _AlertCard(alert: alert);
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(alert.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.severity,
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  _formatDateTime(alert.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Component: ${alert.component}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Status: ${alert.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: alert.status == 'ACTIVE' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
