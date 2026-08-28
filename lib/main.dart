import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/local_db/credential_store.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/shell/main_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In-memory store — selalu sukses, tidak ada I/O yang bisa hang
  await CredentialStore.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NiceGas BioCNG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Auth gate: tidak ada loading screen yang bisa terjebak
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Loading spinner hanya tampil sesaat saat cek sesi awal
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1210),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainShellPage();
    }

    return const LoginPage();
  }
}
