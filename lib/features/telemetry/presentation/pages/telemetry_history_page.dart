import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../providers/telemetry_provider.dart';
import '../../../../core/config/app_config.dart';

class TelemetryHistoryPage extends ConsumerStatefulWidget {
  final String deviceId;

  const TelemetryHistoryPage({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends ConsumerState<TelemetryHistoryPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _component;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to last 24 hours
    _startDate = now.subtract(const Duration(hours: 24));
    _endDate = now;
  }

  Future<void> _selectDateTime(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            _startDate = newDateTime;
          } else {
            _endDate = newDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = TelemetryParams(
      deviceId: widget.deviceId,
      startTime: _startDate,
      endTime: _endDate,
      component: _component,
    );

    final telemetryAsync = ref.watch(telemetryProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry History'),
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
          _DateRangePicker(
            startDate: _startDate,
            endDate: _endDate,
            onSelectStart: () => _selectDateTime(true),
            onSelectEnd: () => _selectDateTime(false),
          ),
          if (_startDate.isAfter(_endDate) || _startDate.isAtSameMomentAs(_endDate))
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Start time must be before end time',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )
          else
            Expanded(
              child: telemetryAsync.when(
                data: (response) {
                  if (response.data.isEmpty) {
                    return const Center(child: Text('No telemetry records found.'));
                  }
                  return _TelemetryList(
                    response: response,
                    onLoadMore: () => ref.read(telemetryProvider(params).notifier).loadMore(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _ErrorState(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(telemetryProvider(params)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onSelectStart;
  final VoidCallback onSelectEnd;

  const _DateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onSelectStart,
    required this.onSelectEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Row(
        children: [
          Expanded(
            child: _DateTimeButton(
              label: 'From',
              dateTime: startDate,
              onTap: onSelectStart,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
          Expanded(
            child: _DateTimeButton(
              label: 'To',
              dateTime: endDate,
              onTap: onSelectEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.label,
    required this.dateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              _formatDateTime(dateTime),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TelemetryList extends StatelessWidget {
  final dynamic response;
  final VoidCallback onLoadMore;

  const _TelemetryList({required this.response, required this.onLoadMore});

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

        final telemetry = response.data[index];
        return _TelemetryCard(telemetry: telemetry);
      },
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final TelemetryModel telemetry;

  const _TelemetryCard({required this.telemetry});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  telemetry.component ?? 'Device',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  _formatTime(telemetry.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            ...telemetry.metrics.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ')),
                      Text(
                        '${e.value.value} ${e.value.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
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
