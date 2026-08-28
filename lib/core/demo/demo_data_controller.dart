import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/telemetry_model.dart';
import '../../shared/models/alert_model.dart';
import '../../shared/models/device_model.dart';

/// State for the demo simulation.
class DemoState {
  final List<DeviceModel> devices;
  final List<TelemetryModel> telemetryHistory;
  final List<AlertModel> alerts;
  final int step;

  DemoState({
    required this.devices,
    required this.telemetryHistory,
    required this.alerts,
    required this.step,
  });

  DemoState copyWith({
    List<DeviceModel>? devices,
    List<TelemetryModel>? telemetryHistory,
    List<AlertModel>? alerts,
    int? step,
  }) {
    return DemoState(
      devices: devices ?? this.devices,
      telemetryHistory: telemetryHistory ?? this.telemetryHistory,
      alerts: alerts ?? this.alerts,
      step: step ?? this.step,
    );
  }
}

/// Controller responsible for maintaining and updating demo simulation data.
class DemoDataController extends StateNotifier<DemoState> {
  Timer? _timer;
  
  static const String demoDeviceId = 'DEMO-001';
  static const String demoProjectId = 'DEMO-PROJECT-001';
  
  DemoDataController() : super(_initialState()) {
    _startSimulation();
  }

  static DemoState _initialState() {
    final now = DateTime.now();
    final devices = [
      DeviceModel(
        id: demoDeviceId,
        name: 'ESP32-001 Digester',
        type: 'ESP32',
        status: 'ONLINE',
        lastSeen: now,
        firmware: 'v1.0.0-demo',
      ),
      const DeviceModel(
        id: 'DEMO-002',
        name: 'Gas Holder Unit',
        type: 'ESP32',
        status: 'ONLINE',
      ),
      const DeviceModel(
        id: 'DEMO-003',
        name: 'Compressor Unit',
        type: 'ESP32',
        status: 'OFFLINE',
      ),
    ];

    // Seed some history
    final history = List.generate(20, (i) {
      final ts = now.subtract(Duration(minutes: i * 2));
      return TelemetryModel(
        timestamp: ts,
        deviceId: demoDeviceId,
        component: 'Digester',
        metrics: {
          'temperature': MetricValue(value: 38.1 + (i % 5) * 0.1, unit: '°C'),
          'pressure': MetricValue(value: 1.18 + (i % 3) * 0.02, unit: 'bar'),
          'methane': MetricValue(value: 60.5 + (i % 4) * 0.1, unit: '%'),
          'gas_flow': MetricValue(value: 22.5 + (i % 6) * 0.1, unit: 'Nm³/h'),
        },
        status: 'OK',
      );
    });

    return DemoState(
      devices: devices,
      telemetryHistory: history,
      alerts: [],
      step: 0,
    );
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _tick();
    });
  }

  void _tick() {
    final nextStep = (state.step + 1) % 60; // Reset every 2 minutes
    final now = DateTime.now();
    
    // 1. Telemetry Simulation
    double temp = 38.1 + (0.6 * (nextStep % 10) / 10);
    double methane = 60.5 + (0.9 * (nextStep % 15) / 15);
    double flow = 22.5 + (0.9 * (nextStep % 12) / 12);
    
    // Pressure sequence for alert scenario
    double pressure;
    if (nextStep < 15) {
      pressure = 1.18 + (0.12 * nextStep / 15); // Normal range [1.18 - 1.30]
    } else if (nextStep < 25) {
      pressure = 1.30 + (0.15 * (nextStep - 15) / 10); // Warning range [1.30 - 1.45]
    } else if (nextStep < 35) {
      pressure = 1.45 + (0.15 * (nextStep - 25) / 10); // Critical range [1.45 - 1.60]
    } else if (nextStep < 45) {
      pressure = 1.60 - (0.42 * (nextStep - 35) / 10); // Recovery [1.60 - 1.18]
    } else {
      pressure = 1.18 + (0.02 * (nextStep - 45) / 15); // Stable normal
    }

    final newTelemetry = TelemetryModel(
      timestamp: now,
      deviceId: demoDeviceId,
      component: 'Digester',
      metrics: {
        'temperature': MetricValue(value: temp, unit: '°C'),
        'pressure': MetricValue(value: pressure, unit: 'bar'),
        'methane': MetricValue(value: methane, unit: '%'),
        'gas_flow': MetricValue(value: flow, unit: 'Nm³/h'),
      },
      status: 'OK',
    );

    final updatedHistory = [newTelemetry, ...state.telemetryHistory].take(50).toList();

    // 2. Alert Simulation
    List<AlertModel> updatedAlerts = List.from(state.alerts);
    
    if (nextStep == 15) {
      updatedAlerts.insert(0, AlertModel(
        id: 'DEMO-AL-1',
        deviceId: demoDeviceId,
        component: 'Digester',
        severity: 'WARNING',
        status: 'ACTIVE',
        message: 'Pressure approaching demo threshold',
        timestamp: now,
      ));
    } else if (nextStep == 25) {
      updatedAlerts.insert(0, AlertModel(
        id: 'DEMO-AL-2',
        deviceId: demoDeviceId,
        component: 'Digester',
        severity: 'CRITICAL',
        status: 'ACTIVE',
        message: 'High pressure demo event',
        timestamp: now,
      ));
    } else if (nextStep == 40) {
      // Mark as resolved
      updatedAlerts = updatedAlerts.map((a) {
        if (a.status == 'ACTIVE') {
          return AlertModel(
            id: a.id,
            deviceId: a.deviceId,
            component: a.component,
            severity: a.severity,
            status: 'RESOLVED',
            message: a.message.replaceAll('demo event', 'recovered').replaceAll('approaching', 'returned to normal'),
            timestamp: now,
          );
        }
        return a;
      }).toList();
    } else if (nextStep == 0) {
      updatedAlerts = []; // Clear for next cycle
    }

    state = state.copyWith(
      step: nextStep,
      telemetryHistory: updatedHistory,
      alerts: updatedAlerts,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for the [DemoDataController].
final demoDataControllerProvider = StateNotifierProvider.autoDispose<DemoDataController, DemoState>((ref) {
  return DemoDataController();
});
