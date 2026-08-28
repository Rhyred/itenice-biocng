import 'package:freezed_annotation/freezed_annotation.dart';
import '../../shared/models/telemetry_model.dart';

part 'mqtt_state.freezed.dart';

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

@freezed
abstract class MqttState with _$MqttState {
  const factory MqttState({
    @Default(BrokerRole.primary) BrokerRole activeBrokerRole,
    @Default(MqttConnectionStatus.disconnected) MqttConnectionStatus connectionStatus,
    /// Maps compound key (deviceId:component) to TelemetryModel
    @Default({}) Map<String, TelemetryModel> realtimeTelemetry,
    /// Maps deviceId to status ('online' or 'offline')
    @Default({}) Map<String, String> deviceStatus,
  }) = _MqttState;

  const MqttState._();
}
