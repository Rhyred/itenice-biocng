import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A provider for the [MqttService] instance.
final mqttServiceProvider = Provider<MqttService>((ref) {
  return MqttService();
});

/// A service that handles MQTT communication for Bio-CNG hardware connectivity.
class MqttService {
  MqttServerClient? _client;

  /// Connects to the MQTT broker.
  /// Configuration must be injected from environment variables in later phases.
  Future<void> connect({
    required String server,
    required String clientId,
    required int port,
  }) async {
    _client = MqttServerClient.withPort(server, clientId, port);

    // Add connection settings, callbacks, and authentication here.
    
    try {
      await _client?.connect();
    } catch (e) {
      _client?.disconnect();
      rethrow;
    }
  }

  /// Disconnects from the MQTT broker.
  void disconnect() {
    _client?.disconnect();
  }

  /// Subscribes to a topic.
  void subscribe(String topic) {
    _client?.subscribe(topic, MqttQos.atLeastOnce);
  }

  /// Publishes a message to a topic.
  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
