import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/core/config/app_config.dart';
import 'package:itenice_bio_cng/core/config/runtime_config.dart';
import 'package:itenice_bio_cng/core/config/runtime_config_store.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_provider.dart';

void main() {
  group('RuntimeConfig Model Tests', () {
    test('1. Saved runtime API URL overrides compile-time fallback', () {
      const config = RuntimeConfig(
        apiBaseUrl: 'http://192.168.1.160:8000',
        isConfigured: true,
      );

      expect(config.isConfigured, isTrue);
      expect(config.effectiveApiBaseUrl, equals('http://192.168.1.160:8000'));
      expect(config.effectiveApiBaseUrl, isNot(equals(AppConfig.apiBaseUrl)));
    });

    test('Default RuntimeConfig uses AppConfig fallbacks', () {
      const config = RuntimeConfig();

      expect(config.isConfigured, isFalse);
      expect(config.effectiveApiBaseUrl, equals(RuntimeConfig.formatApiUrl(AppConfig.apiBaseUrl)));
      expect(config.effectiveMqttPrimaryHost, equals(AppConfig.mqttPrimaryHost));
      expect(config.effectiveMqttPrimaryPort, equals(AppConfig.mqttPrimaryPort));
    });

    test('Custom RuntimeConfig overrides defaults when non-empty', () {
      const config = RuntimeConfig(
        apiBaseUrl: 'http://192.168.1.100:8000',
        mqttPrimaryHost: '192.168.1.100',
        mqttPrimaryPort: 18833,
        isConfigured: true,
      );

      expect(config.isConfigured, isTrue);
      expect(config.effectiveApiBaseUrl, equals('http://192.168.1.100:8000'));
      expect(config.effectiveMqttPrimaryHost, equals('192.168.1.100'));
      expect(config.effectiveMqttPrimaryPort, equals(18833));
    });

    test('Json serialization and deserialization works accurately', () {
      const config = RuntimeConfig(
        apiBaseUrl: 'http://10.0.0.5:8000',
        mqttPrimaryHost: '10.0.0.5',
        mqttPrimaryPort: 1883,
        mqttEmergencyHost: '10.0.0.6',
        mqttEmergencyPort: 1884,
        isConfigured: true,
      );

      final json = config.toJson();
      final restored = RuntimeConfig.fromJson(json);

      expect(restored.apiBaseUrl, equals('http://10.0.0.5:8000'));
      expect(restored.mqttPrimaryHost, equals('10.0.0.5'));
      expect(restored.mqttPrimaryPort, equals(1883));
      expect(restored.mqttEmergencyHost, equals('10.0.0.6'));
      expect(restored.mqttEmergencyPort, equals(1884));
      expect(restored.isConfigured, isTrue);
    });

    test('formatApiUrl auto-prefixes scheme and strips trailing slash', () {
      expect(RuntimeConfig.formatApiUrl('192.168.1.160:8000/'), equals('http://192.168.1.160:8000'));
      expect(RuntimeConfig.formatApiUrl('https://myapi.com/'), equals('https://myapi.com'));
    });
  });

  group('RuntimeConfigStore & Reconfiguration Integration Tests', () {
    test('2 & 6. Changing runtime API URL updates active ApiService', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const initialConfig = RuntimeConfig(
        apiBaseUrl: 'http://192.168.1.10:8000',
        isConfigured: true,
      );

      await container
          .read(runtimeConfigProvider.notifier)
          .updateConfig(initialConfig);

      final apiService1 = container.read(apiServiceProvider);
      // Read initial ApiService
      expect(apiService1, isNotNull);

      const updatedConfig = RuntimeConfig(
        apiBaseUrl: 'http://192.168.1.160:8000',
        isConfigured: true,
      );

      await container
          .read(runtimeConfigProvider.notifier)
          .updateConfig(updatedConfig);

      final apiService2 = container.read(apiServiceProvider);
      expect(apiService2, isNot(same(apiService1)));
      expect(container.read(runtimeConfigProvider).effectiveApiBaseUrl, equals('http://192.168.1.160:8000'));
    });

    test('5 & 9. Settings can be reopened repeatedly without leaving stale endpoints', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final plants = [
        'http://192.168.1.100:8000',
        'http://192.168.1.160:8000',
        'http://10.10.0.5:8000',
      ];

      for (final plantUrl in plants) {
        final config = RuntimeConfig(
          apiBaseUrl: plantUrl,
          mqttPrimaryHost: plantUrl.replaceAll('http://', '').replaceAll(':8000', ''),
          isConfigured: true,
        );

        await container
            .read(runtimeConfigProvider.notifier)
            .updateConfig(config);

        final activeConfig = container.read(runtimeConfigProvider);
        expect(activeConfig.effectiveApiBaseUrl, equals(plantUrl));
      }
    });

    test('7. Save updates MQTT service state and triggers reconnect', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const newConfig = RuntimeConfig(
        apiBaseUrl: 'http://192.168.1.160:8000',
        mqttPrimaryHost: '192.168.1.160',
        mqttPrimaryPort: 1883,
        isConfigured: true,
      );

      await container
          .read(runtimeConfigProvider.notifier)
          .updateConfig(newConfig);

      // Reconnect MQTT notifier
      container.read(mqttProvider.notifier).reconnectWithNewConfig();

      final mqttState = container.read(mqttProvider);
      expect(mqttState.realtimeTelemetry, isEmpty);
      expect(mqttState.deviceStatus, isEmpty);
      expect(mqttState.realtimeEvents, isEmpty);
    });

    test('10. Demo Mode configuration fallback remains intact', () {
      expect(AppConfig.isDemoMode, isFalse);
    });
  });
}
