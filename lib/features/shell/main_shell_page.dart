import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../../core/widgets/global_header.dart';
import '../dashboard/presentation/pages/dashboard_page.dart';
import '../ai/presentation/pages/ai_assistant_page.dart';
import '../profile/presentation/pages/profile_page.dart';
import '../alerts/presentation/pages/alerts_page.dart';
import '../devices/presentation/pages/device_list_page.dart';
import '../projects/presentation/providers/project_provider.dart';
import '../dashboard/presentation/providers/dashboard_provider.dart';

/// Provider untuk mengontrol tab aktif dari luar
final shellTabProvider = StateProvider<int>((ref) => 0);

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  static const _pages = [
    DashboardTab(),
    AlertsTab(),
    AiAssistantPage(),
    DevicesTab(),
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
      extendBody: true,
      appBar: const GlobalHeader(),
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // White container
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', index: 0, currentIndex: currentIndex)),
                    Expanded(child: _NavItem(icon: Icons.warning_rounded, label: 'Logs', index: 1, currentIndex: currentIndex)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 46), // Space for circle
                          Text(
                            'AI Assist',
                            style: TextStyle(
                              color: currentIndex == 2 ? AppTheme.primary : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: currentIndex == 2 ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ), // Center slot
                    Expanded(child: _NavItem(icon: Icons.schema_rounded, label: 'Nodes', index: 3, currentIndex: currentIndex)),
                    Expanded(child: _NavItem(icon: Icons.person_rounded, label: 'Profil', index: 4, currentIndex: currentIndex)),
                  ],
                ),
              ),

              // Center floating button
              Positioned(
                top: -24,
                child: GestureDetector(
                  onTap: () => ref.read(shellTabProvider.notifier).state = 2,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppTheme.primary : AppTheme.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(shellTabProvider.notifier).state = index,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) => const DashboardPage();
}

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) => const AlertsPage();
}

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) => const DeviceListPage();
}
