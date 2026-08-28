import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../shared/models/device_list_response.dart';
import '../../../../shared/models/device_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';

/// A provider that fetches the device list for a specific project.
final deviceListProvider = FutureProvider.autoDispose.family<DeviceListResponse, String?>((ref, projectId) async {
  if (AppConfig.isDemoMode) {
    final demoState = ref.read(demoDataControllerProvider);
    return DeviceListResponse(
      data: demoState.devices,
      meta: const DeviceListMeta(
        totalCount: 3,
        currentPage: 1,
        limit: 10,
        totalPages: 1,
      ),
    );
  }

  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getDevices(projectId: projectId);
  
  if (response.statusCode == 200) {
    return DeviceListResponse.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load devices: ${response.statusMessage}');
  }
});

/// A provider that fetches a single device by its ID.
final deviceDetailProvider = FutureProvider.autoDispose.family<DeviceModel, String>((ref, deviceId) async {
  if (AppConfig.isDemoMode) {
    final demoState = ref.read(demoDataControllerProvider);
    return demoState.devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw Exception('Device not found in demo data'),
    );
  }

  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getDeviceById(deviceId);
  
  if (response.statusCode == 200) {
    return DeviceModel.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load device details: ${response.statusMessage}');
  }
});
