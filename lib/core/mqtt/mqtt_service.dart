import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config/app_config.dart';

/// A provider for the [MqttService] instance.
final mqttServiceProvider = Provider<MqttService>((ref) {
  return MqttService();
});

/// A service that handles MQTT communication for Bio-CNG hardware connectivity.
class MqttService {
  MqttServerClient? _client;
  
  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  Stream<MqttConnectionState> get connectionStateStream => _connectionStateController.stream;

  final _messageController = StreamController<MqttMessagePayload>.broadcast();
  Stream<MqttMessagePayload> get messageStream => _messageController.stream;

  MqttConnectionState get connectionState => _client?.connectionStatus?.state ?? MqttConnectionState.disconnected;

  /// Performs a temporary connection test against a target MQTT broker.
  static Future<bool> testMqttConnection({
    required String host,
    required int port,
    String username = '',
    String password = '',
  }) async {
    if (host.trim().isEmpty) return false;
    final testClient = MqttServerClient.withPort(
      host.trim(),
      'nicegas_test_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );
    testClient.logging(on: false);
    testClient.keepAlivePeriod = 10;

    try {
      if (username.isNotEmpty) {
        await testClient.connect(username, password);
      } else {
        await testClient.connect();
      }

      final isConnected =
          testClient.connectionStatus?.state == MqttConnectionState.connected;
      if (isConnected) {
        testClient.disconnect();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('MqttService: Connection test failed: $e');
      return false;
    }
  }

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    if (AppConfig.isDemoMode) {
      debugPrint('MqttService: Demo mode enabled. Skipping real MQTT connection.');
      return false;
    }

    if (host.isEmpty) {
      debugPrint('MqttService: MQTT host is empty. Cannot connect.');
      return false;
    }

    // Clean up any existing connection
    if (_client != null) {
      _client!.disconnect();
      _client = null;
    }

    _client = MqttServerClient.withPort(
      host,
      AppConfig.mqttClientId,
      port,
    );

    _client!.logging(on: false);
    _client!.keepAlivePeriod = AppConfig.mqttKeepalive;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(AppConfig.mqttClientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      debugPrint('MqttService: Connecting to $host:$port...');
      _connectionStateController.add(MqttConnectionState.connecting);
      
      if (username.isNotEmpty) {
        await _client!.connect(username, password);
      } else {
        await _client!.connect();
      }
    } catch (e) {
      debugPrint('MqttService: Exception during connect - $e');
      _client?.disconnect();
      _connectionStateController.add(MqttConnectionState.faulted);
      return false;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('MqttService: Connected successfully.');
      _connectionStateController.add(MqttConnectionState.connected);

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final topic = c[0].topic;

        _messageController.add(MqttMessagePayload(topic: topic, payload: pt));
      });
      return true;
    } else {
      debugPrint('MqttService: Failed to connect. State: ${_client!.connectionStatus!.state}');
      _client!.disconnect();
      _connectionStateController.add(MqttConnectionState.faulted);
      return false;
    }
  }

  void disconnect() {
    debugPrint('MqttService: Disconnecting...');
    _client?.disconnect();
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void subscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('MqttService: Subscribing to $topic');
      _client?.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void unsubscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('MqttService: Unsubscribing from $topic');
      _client?.unsubscribe(topic);
    }
  }

  void publish(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void _onConnected() {
    debugPrint('MqttService: OnConnected callback');
  }

  void _onDisconnected() {
    debugPrint('MqttService: OnDisconnected callback');
    if (_client?.connectionStatus?.disconnectionOrigin == MqttDisconnectionOrigin.solicited) {
      debugPrint('MqttService: Disconnected intentionally.');
    } else {
      debugPrint('MqttService: Disconnected unexpectedly.');
      _connectionStateController.add(MqttConnectionState.disconnected);
    }
  }

  void _onSubscribed(String topic) {
    debugPrint('MqttService: Subscribed to $topic');
  }

  void _pong() {
    debugPrint('MqttService: Ping response received');
  }

  void dispose() {
    _connectionStateController.close();
    _messageController.close();
  }
}

class MqttMessagePayload {
  final String topic;
  final String payload;

  MqttMessagePayload({required this.topic, required this.payload});
}
