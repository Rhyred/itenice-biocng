/// Model representing the backend health response.
class HealthStatus {
  final String status;
  final String service;
  final String database;

  HealthStatus({
    required this.status,
    required this.service,
    required this.database,
  });

  /// Creates a [HealthStatus] from a JSON map.
  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String? ?? 'unknown',
      database: json['database'] as String? ?? 'unknown',
    );
  }

  /// Helper to check if everything is ok.
  bool get isHealthy => status == 'ok' && database == 'connected';
}
