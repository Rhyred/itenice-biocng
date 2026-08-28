import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_db/credential_store.dart';

/// State autentikasi
class AuthState {
  final bool isLoading;
  final OperatorCredential? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    OperatorCredential? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: clearUser ? null : (user ?? this.user),
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await CredentialStore.getActiveSession();
      state = AuthState(user: session, isLoading: false);
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final credential = await CredentialStore.login(username, password);
    if (credential != null) {
      state = AuthState(user: credential, isLoading: false);
      return true;
    } else {
      state = AuthState(
        isLoading: false,
        error: 'Username atau password salah.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await CredentialStore.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
