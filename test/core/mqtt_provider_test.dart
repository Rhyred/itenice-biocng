import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_provider.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_service.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_state.dart';
import 'package:itenice_bio_cng/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:itenice_bio_cng/shared/models/project_model.dart';

class FakeMqttService implements MqttService {
  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  final _messageController = StreamController<MqttMessagePayload>.broadcast();

  @override
  Stream<MqttConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<MqttMessagePayload> get messageStream => _messageController.stream;

  @override
  MqttConnectionState get connectionState => MqttConnectionState.disconnected;

  List<String> subscribedTopics = [];
  List<String> unsubscribedTopics = [];

  @override
  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    _connectionStateController.add(MqttConnectionState.connected);
    return true;
  }

  @override
  void disconnect() {
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  @override
  void subscribe(String topic) {
    subscribedTopics.add(topic);
  }

  @override
  void unsubscribe(String topic) {
    unsubscribedTopics.add(topic);
    subscribedTopics.remove(topic);
  }

  void simulateMessage(String topic, String payload) {
    _messageController.add(MqttMessagePayload(topic: topic, payload: payload));
  }

  @override
  void publish(String topic, String message) {}

  @override
  void dispose() {
    _connectionStateController.close();
    _messageController.close();
  }
}

void main() {
  group('MQTT Provider Tests', () {
    late ProviderContainer container;
    late FakeMqttService fakeMqtt;

    setUp(() {
      fakeMqtt = FakeMqttService();
      container = ProviderContainer(
        overrides: [
          mqttServiceProvider.overrideWithValue(fakeMqtt),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is Disconnected with empty maps', () {
      final state = container.read(mqttProvider);
      expect(state.connectionStatus, MqttConnectionStatus.connecting);
      expect(state.realtimeTelemetry, isEmpty);
      expect(state.deviceStatus, isEmpty);
      expect(state.realtimeEvents, isEmpty);
    });

    test('A. Project name is used when creating subscription topics (NOT project.id)', () async {
      // Listen to mqttProvider to keep it active
      container.read(mqttProvider);

      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: '1111-2222-3333-4444',
        name: 'Bio-CNG Plant Alpha',
        location: 'Industrial Zone A',
      );

      await Future.delayed(Duration.zero);

      expect(fakeMqtt.subscribedTopics, contains('nicegas/Bio-CNG Plant Alpha/+/telemetry/+'));
      expect(fakeMqtt.subscribedTopics, contains('nicegas/Bio-CNG Plant Alpha/+/event/+'));
      expect(fakeMqtt.subscribedTopics, contains('nicegas/Bio-CNG Plant Alpha/+/status/connection'));
      expect(fakeMqtt.subscribedTopics.any((t) => t.contains('1111-2222-3333-4444')), isFalse);
    });

    test('B. Status JSON online -> device status online', () async {
      container.read(mqttProvider);
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'uuid-1',
        name: 'Bio-CNG Plant Alpha',
        location: 'Site 1',
      );

      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/status/connection',
        '{"status":"online","timestamp":"2026-09-06T10:00:00Z"}',
      );

      await Future.delayed(Duration.zero);

      final state = container.read(mqttProvider);
      expect(state.deviceStatus['DIGESTER-01'], equals('online'));
    });

    test('C. Status JSON offline -> device status offline', () async {
      container.read(mqttProvider);
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'uuid-1',
        name: 'Bio-CNG Plant Alpha',
        location: 'Site 1',
      );

      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/status/connection',
        '{"status":"offline","timestamp":"2026-09-06T10:00:00Z"}',
      );

      await Future.delayed(Duration.zero);

      final state = container.read(mqttProvider);
      expect(state.deviceStatus['DIGESTER-01'], equals('offline'));
    });

    test('D. Raw online string fallback -> device status online', () async {
      container.read(mqttProvider);
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'uuid-1',
        name: 'Bio-CNG Plant Alpha',
        location: 'Site 1',
      );

      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/status/connection',
        'online',
      );

      await Future.delayed(Duration.zero);

      final state = container.read(mqttProvider);
      expect(state.deviceStatus['DIGESTER-01'], equals('online'));
    });

    test('E. Malformed JSON or unknown status string does not crash and defaults safely', () async {
      container.read(mqttProvider);
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'uuid-1',
        name: 'Bio-CNG Plant Alpha',
        location: 'Site 1',
      );

      // Malformed JSON
      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/status/connection',
        '{"status": "online", corrupted_json',
      );

      await Future.delayed(Duration.zero);

      var state = container.read(mqttProvider);
      expect(state.deviceStatus['DIGESTER-01'], equals('offline'));

      // Empty string
      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-02/status/connection',
        '',
      );

      await Future.delayed(Duration.zero);

      state = container.read(mqttProvider);
      expect(state.deviceStatus['DIGESTER-02'], equals('offline'));
    });

    test('F. Project switching unsubscribes from old project and clears realtime state', () async {
      container.read(mqttProvider);

      // Select Project A
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'uuid-alpha',
        name: 'Bio-CNG Plant Alpha',
        location: 'Site Alpha',
      );

      await Future.delayed(Duration.zero);

      // Populate telemetry & status in Project A
      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/telemetry/biodigester',
        '{"timestamp": "2026-09-06T10:00:00.000Z", "status": "nominal", "metrics": {"temperature": {"v": 38.5, "u": "C"}}}',
      );
      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/status/connection',
        '{"status":"online"}',
      );

      await Future.delayed(Duration.zero);

      var state = container.read(mqttProvider);
      expect(state.realtimeTelemetry['DIGESTER-01:biodigester'], isNotNull);
      expect(state.deviceStatus['DIGESTER-01'], equals('online'));

      // Switch to Project B
      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'uuid-beta',
        name: 'Bio-CNG Plant Beta',
        location: 'Site Beta',
      );

      await Future.delayed(Duration.zero);

      // Verify unsubscription from Project A
      expect(fakeMqtt.unsubscribedTopics, contains('nicegas/Bio-CNG Plant Alpha/+/telemetry/+'));
      expect(fakeMqtt.unsubscribedTopics, contains('nicegas/Bio-CNG Plant Alpha/+/event/+'));
      expect(fakeMqtt.unsubscribedTopics, contains('nicegas/Bio-CNG Plant Alpha/+/status/connection'));

      // Verify subscription to Project B
      expect(fakeMqtt.subscribedTopics, contains('nicegas/Bio-CNG Plant Beta/+/telemetry/+'));
      expect(fakeMqtt.subscribedTopics, contains('nicegas/Bio-CNG Plant Beta/+/event/+'));
      expect(fakeMqtt.subscribedTopics, contains('nicegas/Bio-CNG Plant Beta/+/status/connection'));

      // Verify state was cleared on project switch
      state = container.read(mqttProvider);
      expect(state.realtimeTelemetry, isEmpty);
      expect(state.deviceStatus, isEmpty);
      expect(state.realtimeEvents, isEmpty);

      // Telemetry from old project (Alpha) should be ignored
      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Alpha/DIGESTER-01/telemetry/biodigester',
        '{"timestamp": "2026-09-06T10:01:00.000Z", "status": "nominal", "metrics": {"temperature": {"v": 39.0, "u": "C"}}}',
      );

      await Future.delayed(Duration.zero);

      state = container.read(mqttProvider);
      expect(state.realtimeTelemetry, isEmpty);

      // Telemetry from new project (Beta) should be accepted
      fakeMqtt.simulateMessage(
        'nicegas/Bio-CNG Plant Beta/DIGESTER-02/telemetry/biodigester',
        '{"timestamp": "2026-09-06T10:02:00.000Z", "status": "nominal", "metrics": {"temperature": {"v": 40.0, "u": "C"}}}',
      );

      await Future.delayed(Duration.zero);

      state = container.read(mqttProvider);
      expect(state.realtimeTelemetry['DIGESTER-02:biodigester'], isNotNull);
      expect(state.realtimeTelemetry['DIGESTER-02:biodigester']!.metrics['temperature']!.value, equals(40.0));
    });
  });
}
