import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../data/models/health_status.dart';

/// A [FutureProvider] that fetches the backend health status.
final healthProvider = FutureProvider.autoDispose<HealthStatus>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  
  // Fetch from /health
  final response = await apiService.getHealth();
  
  // Parse response
  if (response.data is Map<String, dynamic>) {
    return HealthStatus.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw Exception('Invalid response format');
  }
});
