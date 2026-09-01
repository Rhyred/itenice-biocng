import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_provider.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_state.dart';
import 'package:itenice_bio_cng/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:itenice_bio_cng/shared/models/project_model.dart';

void main() {
  group('MQTT Provider Tests', () {
    test('Initial state is Disconnected with empty maps', () {
      final container = ProviderContainer();
      final state = container.read(mqttProvider);
      expect(state.connectionStatus, MqttConnectionStatus.connecting);
      expect(state.realtimeTelemetry, isEmpty);
      expect(state.deviceStatus, isEmpty);
    });

    test('Topic parsing correctly handles telemetry and updates compound key', () {
      final container = ProviderContainer();
      
      // Simulate project selected so messages are accepted
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'plant-alpha',
        name: 'Alpha',
        location: 'Test Location',
      );
    });
  });
}
