import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'runtime_config.dart';

class RuntimeConfigNotifier extends StateNotifier<RuntimeConfig> {
  static const String _boxName = 'runtime_config_box';
  static const String _configKey = 'current_config';
  static Box? _box;

  RuntimeConfigNotifier([RuntimeConfig? initialConfig])
      : super(initialConfig ?? const RuntimeConfig()) {
    _loadFromStorage();
  }

  static Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox(_boxName);
      } else {
        _box = Hive.box(_boxName);
      }
    } catch (e) {
      debugPrint('[RuntimeConfigStore] Failed to open Hive box: $e');
    }
  }

  void _loadFromStorage() {
    try {
      if (_box != null && _box!.containsKey(_configKey)) {
        final raw = _box!.get(_configKey);
        if (raw != null) {
          final map = jsonDecode(raw.toString()) as Map<String, dynamic>;
          state = RuntimeConfig.fromJson(map);
        }
      }
    } catch (e) {
      debugPrint('[RuntimeConfigStore] Failed to load runtime config: $e');
    }
  }

  Future<void> updateConfig(RuntimeConfig newConfig) async {
    state = newConfig.copyWith(isConfigured: true);
    try {
      if (_box != null) {
        await _box!.put(_configKey, jsonEncode(state.toJson()));
      }
    } catch (e) {
      debugPrint('[RuntimeConfigStore] Failed to save runtime config: $e');
    }
  }

  Future<void> resetConfig() async {
    state = const RuntimeConfig();
    try {
      if (_box != null) {
        await _box!.delete(_configKey);
      }
    } catch (e) {
      debugPrint('[RuntimeConfigStore] Failed to reset runtime config: $e');
    }
  }
}

final runtimeConfigProvider =
    StateNotifierProvider<RuntimeConfigNotifier, RuntimeConfig>((ref) {
  return RuntimeConfigNotifier();
});
