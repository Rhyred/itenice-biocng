/// Represents a single telemetry reading from a component.
class TelemetryModel {
  final DateTime timestamp;
  final String? deviceId; // Injected during parsing for MQTT
  final String? component; // Injected during parsing for MQTT
  final Map<String, MetricValue> metrics;
  final String? status;

  const TelemetryModel({
    required this.timestamp,
    this.deviceId,
    this.component,
    required this.metrics,
    this.status,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json, {String? deviceId, String? component}) {
    final metricsMap = (json['metrics'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, MetricValue.fromJson(value as Map<String, dynamic>)),
    );

    return TelemetryModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: deviceId,
      component: component,
      metrics: metricsMap,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics.map((key, value) => MapEntry(key, value.toJson())),
      if (status != null) 'status': status,
    };
  }
}

/// Represents a single metric value and its unit.
class MetricValue {
  final double value;
  final String unit;

  const MetricValue({
    required this.value,
    required this.unit,
  });

  factory MetricValue.fromJson(Map<String, dynamic> json) {
    return MetricValue(
      value: (json['v'] as num).toDouble(),
      unit: json['u'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'v': value,
      'u': unit,
    };
  }
}
