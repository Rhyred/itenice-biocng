import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_provider.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_state.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_service.dart';
import 'package:itenice_bio_cng/core/config/app_config.dart';

class FakeMqttService implements MqttService {
  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  final _messageController = StreamController<MqttMessagePayload>.broadcast();

  @override
  Stream<MqttConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<MqttMessagePayload> get messageStream => _messageController.stream;

  @override
  MqttConnectionState get connectionState => MqttConnectionState.disconnected;

  int connectCalls = 0;
  String? lastHost;
  int? lastPort;

  @override
  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    connectCalls++;
    lastHost = host;
    lastPort = port;
    return true;
  }

  void simulateDisconnect() {
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void simulateConnected() {
    _connectionStateController.add(MqttConnectionState.connected);
  }

  @override
  void disconnect() {}

  @override
  void publish(String topic, String message) {}

  @override
  void subscribe(String topic) {}

  @override
  void unsubscribe(String topic) {}
  
  @override
  void dispose() {
    _connectionStateController.close();
    _messageController.close();
  }
}

void main() {
  group('MQTT Failover Tests', () {
    test('Initial state is primary', () {
      final fakeService = FakeMqttService();
      final container = ProviderContainer(
        overrides: [
          mqttServiceProvider.overrideWithValue(fakeService),
        ],
      );

      final state = container.read(mqttProvider);
      expect(state.activeBrokerRole, BrokerRole.primary);
      expect(state.connectionStatus, MqttConnectionStatus.connecting);
      expect(fakeService.connectCalls, 1);
    });

    test('Switches to emergency after 3 failed reconnects', () async {
      final fakeService = FakeMqttService();
      final container = ProviderContainer(
        overrides: [
          mqttServiceProvider.overrideWithValue(fakeService),
        ],
      );

      // wait for init
      await Future.delayed(const Duration(milliseconds: 10));

      expect(container.read(mqttProvider).activeBrokerRole, BrokerRole.primary);

      // Simulate disconnect 1
      fakeService.simulateDisconnect();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(mqttProvider).activeBrokerRole, BrokerRole.primary);

      // Simulate disconnect 2
      fakeService.simulateDisconnect();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(mqttProvider).activeBrokerRole, BrokerRole.primary);

      // Simulate disconnect 3 (threshold reached)
      fakeService.simulateDisconnect();
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(container.read(mqttProvider).activeBrokerRole, BrokerRole.emergency);
      // Wait for it to connect to emergency
      expect(fakeService.lastHost, AppConfig.mqttEmergencyHost);
    });
  });
}
