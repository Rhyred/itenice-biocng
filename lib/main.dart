import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/runtime_config_store.dart';
import 'core/local_db/credential_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/connection/presentation/pages/connection_setup_page.dart';
import 'features/shell/main_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    await RuntimeConfigNotifier.initialize();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

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

/// Auth gate & Connection Setup Router
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeConfig = ref.watch(runtimeConfigProvider);
    final auth = ref.watch(authProvider);

    // In REAL MODE: if runtime configuration has not been set up, prompt setup
    if (!AppConfig.isDemoMode && !runtimeConfig.isConfigured) {
      return const ConnectionSetupPage();
    }

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
