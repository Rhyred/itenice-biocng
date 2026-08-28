import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../shared/models/telemetry_model.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../config/app_config.dart';
import 'mqtt_service.dart';
import 'mqtt_state.dart';

final mqttProvider = StateNotifierProvider<MqttNotifier, MqttState>((ref) {
  return MqttNotifier(ref);
});

class MqttNotifier extends StateNotifier<MqttState> {
  final Ref _ref;
  String? _currentProjectId;

  int _primaryReconnectAttempts = 0;
  static const int _maxPrimaryReconnectAttempts = 3;
  
  Timer? _reconnectTimer;
  Timer? _primaryProbeTimer;
  int _primaryStabilityCount = 0;

  MqttNotifier(this._ref) : super(const MqttState()) {
    _init();
  }

  void _init() {
    final mqttService = _ref.read(mqttServiceProvider);

    mqttService.connectionStateStream.listen((status) {
      MqttConnectionStatus mappedStatus;
      switch (status) {
        case MqttConnectionState.connected:
          mappedStatus = MqttConnectionStatus.connected;
          if (state.activeBrokerRole == BrokerRole.primary) {
            _primaryReconnectAttempts = 0;
          }
          _resubscribe();
          break;
        case MqttConnectionState.connecting:
          mappedStatus = MqttConnectionStatus.connecting;
          break;
        case MqttConnectionState.disconnected:
          mappedStatus = MqttConnectionStatus.disconnected;
          _handleDisconnect();
          break;
        case MqttConnectionState.faulted:
          mappedStatus = MqttConnectionStatus.error;
          _handleDisconnect();
          break;
        case MqttConnectionState.disconnecting:
        default:
          mappedStatus = MqttConnectionStatus.disconnected;
          break;
      }
      if (mounted) {
        state = state.copyWith(connectionStatus: mappedStatus);
      }
    });

    mqttService.messageStream.listen((msg) {
      _handleIncomingMessage(msg.topic, msg.payload);
    });

    _ref.listen(selectedProjectProvider, (previous, next) {
      final newProjectId = next?.id;
      if (_currentProjectId != newProjectId) {
        if (_currentProjectId != null) {
          _unsubscribeFromProject(_currentProjectId!);
        }
        _currentProjectId = newProjectId;
        if (_currentProjectId != null) {
          _subscribeToProject(_currentProjectId!);
          // Clear previous project telemetry
          state = state.copyWith(
            realtimeTelemetry: {},
            deviceStatus: {},
          );
        }
      }
    });

    _currentProjectId = _ref.read(selectedProjectProvider)?.id;
    
    _connect();
  }

  void _handleDisconnect() {
    if (AppConfig.isDemoMode) return;

    if (state.activeBrokerRole == BrokerRole.primary) {
      _primaryReconnectAttempts++;
      if (_primaryReconnectAttempts >= _maxPrimaryReconnectAttempts) {
        debugPrint('MqttNotifier: Primary reconnect threshold reached. Switching to emergency broker.');
        _switchToEmergency();
      } else {
        _scheduleReconnect();
      }
    } else {
      // Emergency disconnected, try to reconnect to emergency
      _scheduleReconnect();
    }
  }

  void _switchToEmergency() {
    _reconnectTimer?.cancel();
    
    // Switch state to emergency
    state = state.copyWith(activeBrokerRole: BrokerRole.emergency);
    
    // Connect to emergency
    _connect();

    // Start probing primary
    _startPrimaryProbe();
  }

  void _switchToPrimary() {
    _primaryProbeTimer?.cancel();
    _reconnectTimer?.cancel();

    // Reset counters
    _primaryReconnectAttempts = 0;
    _primaryStabilityCount = 0;

    // Switch state back to primary
    state = state.copyWith(activeBrokerRole: BrokerRole.primary);

    // Connect to primary
    _connect();
  }

  void _startPrimaryProbe() {
    _primaryProbeTimer?.cancel();
    _primaryStabilityCount = 0;
    
    _primaryProbeTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      debugPrint('MqttNotifier: Probing primary broker...');
      final isAvailable = await _probePrimary();
      
      if (isAvailable) {
        _primaryStabilityCount++;
        debugPrint('MqttNotifier: Primary broker probe successful. Stability count: $_primaryStabilityCount/2');
        if (_primaryStabilityCount >= 2) {
          debugPrint('MqttNotifier: Primary broker stabilized. Switching back.');
          timer.cancel();
          _switchToPrimary();
        }
      } else {
        debugPrint('MqttNotifier: Primary broker probe failed.');
        _primaryStabilityCount = 0;
      }
    });
  }

  Future<bool> _probePrimary() async {
    if (AppConfig.mqttPrimaryHost.isEmpty) return false;
    
    try {
      final probeClient = MqttServerClient.withPort(
        AppConfig.mqttPrimaryHost,
        '${AppConfig.mqttClientId}_probe',
        AppConfig.mqttPrimaryPort,
      );
      probeClient.logging(on: false);
      probeClient.keepAlivePeriod = 10;
      
      if (AppConfig.mqttPrimaryUsername.isNotEmpty) {
        await probeClient.connect(AppConfig.mqttPrimaryUsername, AppConfig.mqttPrimaryPassword);
      } else {
        await probeClient.connect();
      }

      if (probeClient.connectionStatus?.state == MqttConnectionState.connected) {
        probeClient.disconnect();
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _connect() async {
    _reconnectTimer?.cancel();
    state = state.copyWith(connectionStatus: MqttConnectionStatus.connecting);
    final mqttService = _ref.read(mqttServiceProvider);

    bool isPrimary = state.activeBrokerRole == BrokerRole.primary;
    
    final host = isPrimary ? AppConfig.mqttPrimaryHost : AppConfig.mqttEmergencyHost;
    final port = isPrimary ? AppConfig.mqttPrimaryPort : AppConfig.mqttEmergencyPort;
    final username = isPrimary ? AppConfig.mqttPrimaryUsername : AppConfig.mqttEmergencyUsername;
    final password = isPrimary ? AppConfig.mqttPrimaryPassword : AppConfig.mqttEmergencyPassword;

    await mqttService.connect(
      host: host,
      port: port,
      username: username,
      password: password,
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    debugPrint('MqttNotifier: Scheduling reconnect in 5 seconds...');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && state.connectionStatus != MqttConnectionStatus.connected) {
        _connect();
      }
    });
  }

  void _resubscribe() {
    if (_currentProjectId != null) {
      _subscribeToProject(_currentProjectId!);
    }
  }

  void _subscribeToProject(String projectId) {
    final mqttService = _ref.read(mqttServiceProvider);
    mqttService.subscribe('nicegas/$projectId/+/telemetry/+');
    mqttService.subscribe('nicegas/$projectId/+/status/connection');
  }

  void _unsubscribeFromProject(String projectId) {
    final mqttService = _ref.read(mqttServiceProvider);
    mqttService.unsubscribe('nicegas/$projectId/+/telemetry/+');
    mqttService.unsubscribe('nicegas/$projectId/+/status/connection');
  }

  void _handleIncomingMessage(String topic, String payload) {
    final parts = topic.split('/');
    if (parts.length < 5) return;

    final siteId = parts[1];
    if (siteId != _currentProjectId) return;

    final deviceId = parts[2];
    final category = parts[3];
    final component = parts[4];

    if (category == 'telemetry') {
      try {
        final json = jsonDecode(payload);
        final telemetry = TelemetryModel.fromJson(json, deviceId: deviceId, component: component);
        final key = '$deviceId:$component';

        final updatedTelemetry = Map<String, TelemetryModel>.from(state.realtimeTelemetry);
        updatedTelemetry[key] = telemetry;

        state = state.copyWith(realtimeTelemetry: updatedTelemetry);
      } catch (e) {
        debugPrint('MqttNotifier: Failed to parse telemetry payload: $e');
      }
    } else if (category == 'status' && component == 'connection') {
      final updatedStatus = Map<String, String>.from(state.deviceStatus);
      updatedStatus[deviceId] = payload.trim().toLowerCase();
      state = state.copyWith(deviceStatus: updatedStatus);
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _primaryProbeTimer?.cancel();
    super.dispose();
  }
}
