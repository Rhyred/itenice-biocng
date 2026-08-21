/// Represents a system alert or notification.
class AlertModel {
  final String id;
  final String deviceId;
  final String component;
  final String severity;
  final String status;
  final String message;
  final DateTime timestamp;

  const AlertModel({
    required this.id,
    required this.deviceId,
    required this.component,
    required this.severity,
    required this.status,
    required this.message,
    required this.timestamp,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      component: json['component'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'component': component,
      'severity': severity,
      'status': status,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
