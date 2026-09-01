import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/alert_list_response.dart';
import '../providers/alerts_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/sub_header.dart';

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

    // Demo mode: pakai Provider sinkron — tidak ada loading loop
    // Production: pakai AsyncNotifier yang fetch dari API
    final Widget body;
    if (AppConfig.isDemoMode) {
      final response = ref.watch(demoAlertsProvider(params));
      body = response.data.isEmpty
          ? const Center(child: Text('Belum ada alert.'))
          : _AlertList(
              response: response,
              onLoadMore: () {}, // demo tidak perlu load more
            );
    } else {
      final alertsAsync = ref.watch(alertsProvider(params));
      body = alertsAsync.when(
        data: (response) {
          if (response.data.isEmpty) {
            return const Center(child: Text('No alerts found.'));
          }
          return _AlertList(
            response: response,
            onLoadMore: () =>
                ref.read(alertsProvider(params).notifier).loadMore(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(
          error: err.toString(),
          onRetry: () => ref.invalidate(alertsProvider(params)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: SubHeader(
        title: 'Log System',
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
          Expanded(child: body),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SEVERITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.0)),
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
                  color: AppTheme.statusCritical,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'WARNING',
                  isSelected: selectedSeverity == 'WARNING',
                  onSelected: (_) => onSeverityChanged('WARNING'),
                  color: AppTheme.statusWarning,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'INFO',
                  isSelected: selectedSeverity == 'INFO',
                  onSelected: (_) => onSeverityChanged('INFO'),
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.0)),
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
      selectedColor: color?.withValues(alpha: 0.1) ?? AppTheme.primary.withValues(alpha: 0.1),
      checkmarkColor: color ?? AppTheme.primary,
      backgroundColor: AppTheme.background,
      side: BorderSide(color: isSelected ? (color ?? AppTheme.primary).withValues(alpha: 0.5) : AppTheme.borderColor),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppTheme.primary) : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
                  ),
                ),
                Text(
                  _formatDateTime(alert.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NODE: ${alert.component}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                ),
                Text(
                  alert.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: alert.status == 'ACTIVE' ? AppTheme.statusCritical : AppTheme.statusOptimal,
                    fontWeight: FontWeight.w700,
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
        return AppTheme.statusCritical;
      case 'WARNING':
        return AppTheme.statusWarning;
      case 'INFO':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
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
