import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/core/demo/demo_data_controller.dart';

void main() {
  group('DemoDataController', () {
    test('initializes with default demo data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final state = container.read(demoDataControllerProvider);
      
      expect(state.devices, isNotEmpty);
      expect(state.devices.first.id, DemoDataController.demoDeviceId);
      expect(state.telemetryHistory, isNotEmpty);
      expect(state.step, 0);
    });

    test('advances simulation steps', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Listen to the provider to keep it alive (since it's autoDispose)
      final sub = container.listen(demoDataControllerProvider, (prev, next) {});
      
      final initialState = container.read(demoDataControllerProvider);
      
      // Wait for at least one tick (2 seconds)
      await Future.delayed(const Duration(milliseconds: 2500));
      
      final updatedState = container.read(demoDataControllerProvider);
      expect(updatedState.step, isNot(initialState.step));
      expect(updatedState.telemetryHistory.length, greaterThanOrEqualTo(initialState.telemetryHistory.length));
      
      sub.close();
    });
  });
}
