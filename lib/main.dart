import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell_page.dart';

void main() {
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
      // Langsung ke MainShellPage — project di-select secara otomatis di sana
      home: const MainShellPage(),
    );
  }
}
