import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/health_provider.dart';

/// A simple page to display backend health status.
class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NICEGAS System Health'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(healthProvider.future),
        child: Center(
          child: healthAsync.when(
            data: (health) => _HealthDetails(health: health),
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => _ErrorState(
              error: err.toString(),
              onRetry: () => ref.invalidate(healthProvider),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.invalidate(healthProvider),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _HealthDetails extends StatelessWidget {
  final dynamic health;

  const _HealthDetails({required this.health});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 24),
          _StatusCard(
            label: 'API Status',
            value: health.status.toUpperCase(),
            isOk: health.status == 'ok',
          ),
          _StatusCard(
            label: 'Database',
            value: health.database,
            isOk: health.database == 'connected',
          ),
          _StatusCard(
            label: 'Service',
            value: health.service,
            isOk: true,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOk ? Colors.green : Colors.red,
          ),
        ),
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
            'Connection Error',
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
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }
}
