import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/runtime_config_store.dart';
import '../../../../core/local_db/credential_store.dart';
import '../../../../core/mqtt/mqtt_provider.dart';
import '../../../../core/mqtt/mqtt_service.dart';
import '../../../../shared/models/project_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

enum AuthSessionMode {
  unauthenticated,
  authenticated,
  localMonitoring,
}

/// State autentikasi / sesi
class AuthState {
  final bool isLoading;
  final OperatorCredential? user;
  final AuthSessionMode sessionMode;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.sessionMode = AuthSessionMode.unauthenticated,
    this.error,
  });

  bool get isAuthenticated =>
      sessionMode == AuthSessionMode.authenticated && user != null;

  bool get isLocalMonitoring =>
      sessionMode == AuthSessionMode.localMonitoring;

  bool get isUnauthenticated =>
      sessionMode == AuthSessionMode.unauthenticated;

  AuthState copyWith({
    bool? isLoading,
    OperatorCredential? user,
    AuthSessionMode? sessionMode,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: clearUser ? null : (user ?? this.user),
        sessionMode: sessionMode ?? this.sessionMode,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final session = await CredentialStore.getActiveSession();
      if (session != null) {
        state = AuthState(
          user: session,
          sessionMode: AuthSessionMode.authenticated,
          isLoading: false,
        );
      }
    } catch (_) {
      state = const AuthState(
        sessionMode: AuthSessionMode.unauthenticated,
        isLoading: false,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (AppConfig.isDemoMode) {
      final credential = await CredentialStore.login(username, password);
      if (credential != null) {
        state = AuthState(
          user: credential,
          sessionMode: AuthSessionMode.authenticated,
          isLoading: false,
        );
        return true;
      } else {
        state = const AuthState(
          sessionMode: AuthSessionMode.unauthenticated,
          isLoading: false,
          error: 'Username atau password demo salah.',
        );
        return false;
      }
    }

    // REAL MODE authentication against backend
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.login(username.trim(), password);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token']?.toString();
        final userData = data['user'] as Map<String, dynamic>? ?? {};

        final credential = OperatorCredential(
          username: username.trim(),
          passwordHash: '',
          displayName: userData['name']?.toString() ??
              userData['displayName']?.toString() ??
              username.trim(),
          role: userData['role']?.toString() ?? 'operator',
          token: token,
        );

        await CredentialStore.saveSession(credential);
        state = AuthState(
          user: credential,
          sessionMode: AuthSessionMode.authenticated,
          isLoading: false,
        );
        return true;
      } else {
        state = const AuthState(
          sessionMode: AuthSessionMode.unauthenticated,
          isLoading: false,
          error: 'Autentikasi gagal. Silakan periksa kredensial Anda.',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal terhubung ke server autentikasi.';
      if (e.response != null && e.response?.data != null) {
        final errBody = e.response!.data;
        if (errBody is Map && errBody.containsKey('error')) {
          final errObj = errBody['error'];
          if (errObj is Map && errObj.containsKey('message')) {
            errorMessage = errObj['message'].toString();
          } else if (errObj is String) {
            errorMessage = errObj;
          }
        } else if (errBody is Map && errBody.containsKey('message')) {
          errorMessage = errBody['message'].toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Koneksi ke server timeout/gagal. Periksa alamat API.';
      }
      state = AuthState(
        sessionMode: AuthSessionMode.unauthenticated,
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = AuthState(
        sessionMode: AuthSessionMode.unauthenticated,
        isLoading: false,
        error: 'Terjadi kesalahan sistem: $e',
      );
      return false;
    }
  }

  /// Restrictive Local Monitoring Entry Flow
  Future<bool> enterLocalMonitoring() async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (AppConfig.isDemoMode) {
      state = const AuthState(
        sessionMode: AuthSessionMode.unauthenticated,
        isLoading: false,
        error: 'Mode Pemantauan Lokal hanya dapat digunakan dalam Mode REAL.',
      );
      return false;
    }

    final runtimeConfig = _ref.read(runtimeConfigProvider);
    final emergencyHost = runtimeConfig.mqttEmergencyHost.trim().isNotEmpty
        ? runtimeConfig.mqttEmergencyHost.trim()
        : AppConfig.mqttEmergencyHost.trim();
    final emergencyPort = runtimeConfig.effectiveMqttEmergencyPort;
    final emergencyUsername = runtimeConfig.effectiveMqttEmergencyUsername;
    final emergencyPassword = runtimeConfig.effectiveMqttEmergencyPassword;

    if (runtimeConfig.mqttEmergencyHost.trim().isEmpty && AppConfig.mqttEmergencyHost.trim().isEmpty) {
      state = const AuthState(
        sessionMode: AuthSessionMode.unauthenticated,
        isLoading: false,
        error: 'Emergency monitoring unavailable. Please check the configured emergency broker.',
      );
      return false;
    }

    // Lightweight connection test to Emergency MQTT broker
    final success = await MqttService.testMqttConnection(
      host: emergencyHost,
      port: emergencyPort,
      username: emergencyUsername,
      password: emergencyPassword,
    );

    if (!success) {
      state = const AuthState(
        sessionMode: AuthSessionMode.unauthenticated,
        isLoading: false,
        error: 'Emergency monitoring unavailable. Please check the configured emergency broker.',
      );
      return false;
    }

    // Ensure selected project is set for topic scoping
    _ref.read(selectedProjectProvider.notifier).state = ProjectModel(
      id: runtimeConfig.effectiveSiteId,
      name: runtimeConfig.effectivePlantName,
      location: 'Local Emergency Broker',
    );

    // Set Local Monitoring state
    state = const AuthState(
      sessionMode: AuthSessionMode.localMonitoring,
      user: null,
      isLoading: false,
    );

    // Trigger MqttNotifier to start in Local Monitoring Mode (Emergency broker)
    _ref.read(mqttProvider.notifier).startLocalMonitoring();

    return true;
  }

  /// Leaves Local Monitoring Mode and returns to Login page
  void switchToLogin() {
    state = const AuthState(
      sessionMode: AuthSessionMode.unauthenticated,
      user: null,
      isLoading: false,
    );
    _ref.read(mqttProvider.notifier).reconnectWithNewConfig();
  }

  Future<void> logout() async {
    await CredentialStore.logout();
    state = const AuthState(
      sessionMode: AuthSessionMode.unauthenticated,
      user: null,
      isLoading: false,
    );
    _ref.read(mqttProvider.notifier).reconnectWithNewConfig();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
