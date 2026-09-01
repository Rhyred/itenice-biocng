import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../dashboard/presentation/pages/dashboard_page.dart';
import '../ai/presentation/pages/ai_assistant_page.dart';
import '../profile/presentation/pages/profile_page.dart';
import '../projects/presentation/providers/project_provider.dart';
import '../dashboard/presentation/providers/dashboard_provider.dart';

/// Provider untuk mengontrol tab aktif dari luar
final shellTabProvider = StateProvider<int>((ref) => 0);

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  static const _pages = [
    DashboardTab(),
    AiAssistantPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellTabProvider);
    final isLocalMonitoring = ref.watch(authProvider).isLocalMonitoring;

    if (!isLocalMonitoring) {
      // Auto-select project pertama dalam mode Authenticated / Demo
      ref.listen<AsyncValue>(projectProvider, (_, next) {
        next.whenData((response) {
          if (ref.read(selectedProjectProvider) == null &&
              response.data.isNotEmpty) {
            ref.read(selectedProjectProvider.notifier).state =
                response.data.first;
          }
        });
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: AppTheme.borderColor, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) =>
              ref.read(shellTabProvider.notifier).state = index,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Pemeliharaan AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) => const DashboardPage();
}
