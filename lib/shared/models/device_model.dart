/// Represents a hardware device (e.g., ESP32).
class DeviceModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final String? firmwareVersion;
  final DateTime? lastSeen;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.firmwareVersion,
    this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'ESP32',
      status: json['status'] as String,
      firmwareVersion: json['firmware_version'] as String?,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'firmware_version': firmwareVersion,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
