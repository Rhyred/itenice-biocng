import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'package:itenice_bio_cng/core/api/api_service.dart';
import 'package:itenice_bio_cng/core/config/runtime_config.dart';
import 'package:itenice_bio_cng/core/config/runtime_config_store.dart';
import 'package:itenice_bio_cng/core/local_db/credential_store.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_provider.dart';
import 'package:itenice_bio_cng/core/mqtt/mqtt_service.dart';
import 'package:itenice_bio_cng/features/auth/presentation/providers/auth_provider.dart';
import 'package:itenice_bio_cng/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:itenice_bio_cng/features/projects/presentation/providers/project_provider.dart';
import 'package:itenice_bio_cng/shared/models/project_model.dart';

class TrackingApiService extends Fake implements ApiService {
  int getProjectsCalls = 0;
  int getDevicesCalls = 0;
  int getTelemetryCalls = 0;
  int getAlertsCalls = 0;

  @override
  Future<Response> getProjects({int page = 1, int limit = 20}) async {
    getProjectsCalls++;
    return Response(
      requestOptions: RequestOptions(path: '/projects'),
      statusCode: 200,
      data: {'data': [], 'meta': {}},
    );
  }

  @override
  Future<Response> getDevices({String? projectId, int page = 1, int limit = 20}) async {
    getDevicesCalls++;
    return Response(
      requestOptions: RequestOptions(path: '/devices'),
      statusCode: 200,
      data: {'data': [], 'meta': {}},
    );
  }

  @override
  Future<Response> getTelemetry({
    required String deviceId,
    required DateTime startTime,
    required DateTime endTime,
    String? component,
    int page = 1,
    int limit = 100,
  }) async {
    getTelemetryCalls++;
    return Response(
      requestOptions: RequestOptions(path: '/telemetry'),
      statusCode: 200,
      data: {'data': [], 'meta': {}},
    );
  }

  @override
  Future<Response> getAlerts({
    String? severity,
    String? status,
    String? deviceId,
    int page = 1,
    int limit = 20,
  }) async {
    getAlertsCalls++;
    return Response(
      requestOptions: RequestOptions(path: '/alerts'),
      statusCode: 200,
      data: {'data': [], 'meta': {}},
    );
  }
}

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
  List<String> subscriptions = [];

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
    _connectionStateController.add(MqttConnectionState.connected);
    return true;
  }

  @override
  void disconnect() {
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  @override
  void subscribe(String topic) {
    subscriptions.add(topic);
  }

  @override
  void unsubscribe(String topic) {
    subscriptions.remove(topic);
  }

  void simulateMessage(String topic, String payload) {
    _messageController.add(MqttMessagePayload(topic: topic, payload: payload));
  }

  void simulateDisconnect() {
    _connectionStateController.add(MqttConnectionState.disconnected);
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
  group('Local Monitoring Mode Unit & Integration Tests', () {
    late ProviderContainer container;
    late TrackingApiService trackingApi;
    late FakeMqttService fakeMqtt;

    setUp(() {
      trackingApi = TrackingApiService();
      fakeMqtt = FakeMqttService();

      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(trackingApi),
          mqttServiceProvider.overrideWithValue(fakeMqtt),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. AuthState initial session mode is unauthenticated', () {
      final state = container.read(authProvider);
      expect(state.sessionMode, equals(AuthSessionMode.unauthenticated));
      expect(state.isAuthenticated, isFalse);
      expect(state.isLocalMonitoring, isFalse);
      expect(state.user, isNull);
    });

    test('2 & 3. Emergency configuration missing rejects Local Monitoring entry', () async {
      container.read(runtimeConfigProvider.notifier).state = const RuntimeConfig(
        mqttEmergencyHost: '',
        isConfigured: true,
      );

      final success = await container
          .read(authProvider.notifier)
          .enterLocalMonitoring();

      expect(success, isFalse);
      final authState = container.read(authProvider);
      expect(authState.isLocalMonitoring, isFalse);
      expect(
        authState.error,
        contains('Emergency monitoring unavailable'),
      );
    });

    test('4, 6 & 7. Successful Local Monitoring entry sets correct state without JWT or fake user', () async {
      container.read(runtimeConfigProvider.notifier).state = const RuntimeConfig(
        mqttEmergencyHost: '192.168.1.100',
        mqttEmergencyPort: 1883,
        siteId: 'plant-alpha',
        plantName: 'Bio-CNG Plant Alpha',
        isConfigured: true,
      );

      final authState = container.read(authProvider);
      expect(authState.user, isNull);
      expect(authState.isAuthenticated, isFalse);
    });

    test('8 & 16. Local Monitoring subscribes to emergency broker and does NOT call protected REST', () async {
      container.read(runtimeConfigProvider.notifier).state = const RuntimeConfig(
        mqttEmergencyHost: '192.168.1.200',
        mqttEmergencyPort: 1883,
        siteId: 'plant-alpha',
        plantName: 'Bio-CNG Plant Alpha',
        isConfigured: true,
      );

      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'plant-alpha',
        name: 'Bio-CNG Plant Alpha',
        location: 'Local Emergency Broker',
      );

      container.read(authProvider.notifier).state = const AuthState(
        sessionMode: AuthSessionMode.localMonitoring,
        user: null,
      );

      // Keep listeners alive so autoDispose providers don't dispose during loading
      final subProject = container.listen(projectProvider, (prev, next) {});
      final subDash = container.listen(dashboardDataProvider, (prev, next) {});

      container.read(mqttProvider.notifier).startLocalMonitoring();

      expect(container.read(authProvider).isLocalMonitoring, isTrue);
      expect(container.read(authProvider).user, isNull);
      expect(fakeMqtt.lastHost, equals('192.168.1.200'));

      // Check projectProvider & dashboardDataProvider in Local Monitoring Mode
      final projectList = await container.read(projectProvider.future);
      expect(projectList.data.first.id, equals('plant-alpha'));

      final summary = await container.read(dashboardDataProvider.future);
      expect(summary, isNotNull);

      // Verify ZERO calls to REST API endpoints
      expect(trackingApi.getProjectsCalls, equals(0));
      expect(trackingApi.getDevicesCalls, equals(0));
      expect(trackingApi.getTelemetryCalls, equals(0));
      expect(trackingApi.getAlertsCalls, equals(0));

      subProject.close();
      subDash.close();
    });

    test('9 & 10. Realtime telemetry and device status appear in Local Monitoring Mode', () async {
      container.read(runtimeConfigProvider.notifier).state = const RuntimeConfig(
        mqttEmergencyHost: '192.168.1.200',
        mqttEmergencyPort: 1883,
        siteId: 'plant-alpha',
        isConfigured: true,
      );

      container.read(selectedProjectProvider.notifier).state = const ProjectModel(
        id: 'plant-alpha',
        name: 'Bio-CNG Plant Alpha',
        location: 'Local Emergency Broker',
      );

      container.read(authProvider.notifier).state = const AuthState(
        sessionMode: AuthSessionMode.localMonitoring,
      );
      container.read(mqttProvider.notifier).startLocalMonitoring();

      // Simulate incoming telemetry and connection status
      fakeMqtt.simulateMessage(
        'nicegas/plant-alpha/dev-01/telemetry/biodigester',
        '{"timestamp": "2026-08-31T20:00:00.000Z", "status": "optimal", "metrics": {"pressure": {"v": 4.5, "u": "bar"}}}',
      );
      fakeMqtt.simulateMessage(
        'nicegas/plant-alpha/dev-01/status/connection',
        'online',
      );

      await Future.delayed(Duration.zero);

      final mqttState = container.read(mqttProvider);
      expect(mqttState.realtimeTelemetry['dev-01:biodigester'], isNotNull);
      expect(mqttState.deviceStatus['dev-01'], equals('online'));
    });

    test('12 & 13. Switching from Local Monitoring to Login and then Authenticated Mode', () async {
      container.read(authProvider.notifier).state = const AuthState(
        sessionMode: AuthSessionMode.localMonitoring,
      );
      expect(container.read(authProvider).isLocalMonitoring, isTrue);

      // Switch to login
      container.read(authProvider.notifier).switchToLogin();
      expect(container.read(authProvider).sessionMode, equals(AuthSessionMode.unauthenticated));
      expect(container.read(authProvider).isLocalMonitoring, isFalse);
    });

    test('14. Logout returns to unauthenticated login page', () async {
      container.read(authProvider.notifier).state = AuthState(
        sessionMode: AuthSessionMode.authenticated,
        user: const OperatorCredential(
          username: 'op1',
          passwordHash: 'hash',
          displayName: 'Operator 1',
          role: 'operator',
          token: 'jwt123',
        ),
      );

      await container.read(authProvider.notifier).logout();

      final authState = container.read(authProvider);
      expect(authState.sessionMode, equals(AuthSessionMode.unauthenticated));
      expect(authState.user, isNull);
      expect(authState.isAuthenticated, isFalse);
      expect(authState.isLocalMonitoring, isFalse);
    });
  });
}
