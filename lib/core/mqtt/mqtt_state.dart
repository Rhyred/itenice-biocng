import '../../shared/models/telemetry_model.dart';

enum MqttConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

enum BrokerRole {
  primary,
  emergency,
}

class MqttState {
  final BrokerRole activeBrokerRole;
  final MqttConnectionStatus connectionStatus;
  /// Maps compound key (deviceId:component) to TelemetryModel
  final Map<String, TelemetryModel> realtimeTelemetry;
  /// Maps deviceId to status ('online' or 'offline')
  final Map<String, String> deviceStatus;
  /// Maps compound key (deviceId:component) to event payload
  final Map<String, TelemetryModel> realtimeEvents;

  const MqttState({
    this.activeBrokerRole = BrokerRole.primary,
    this.connectionStatus = MqttConnectionStatus.disconnected,
    this.realtimeTelemetry = const {},
    this.deviceStatus = const {},
    this.realtimeEvents = const {},
  });

  MqttState copyWith({
    BrokerRole? activeBrokerRole,
    MqttConnectionStatus? connectionStatus,
    Map<String, TelemetryModel>? realtimeTelemetry,
    Map<String, String>? deviceStatus,
    Map<String, TelemetryModel>? realtimeEvents,
  }) {
    return MqttState(
      activeBrokerRole: activeBrokerRole ?? this.activeBrokerRole,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      realtimeTelemetry: realtimeTelemetry ?? this.realtimeTelemetry,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      realtimeEvents: realtimeEvents ?? this.realtimeEvents,
    );
  }
}
