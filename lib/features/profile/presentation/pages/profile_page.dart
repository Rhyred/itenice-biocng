import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itenice_bio_cng/features/connection/presentation/pages/connection_setup_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/sub_header.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isLocalMonitoring = auth.isLocalMonitoring;

    return Scaffold(
      appBar: const SubHeader(title: 'Profil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + Info
            _AppCard(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isLocalMonitoring ? AppTheme.statusWarning : AppTheme.primary)
                              .withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLocalMonitoring
                        ? 'Local Monitor'
                        : (user?.displayName ?? 'Operator Lapangan'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isLocalMonitoring ? AppTheme.statusWarning : AppTheme.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLocalMonitoring
                          ? 'LOCAL MONITORING MODE'
                          : (user?.role.toUpperCase() ?? 'OPERATOR'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLocalMonitoring ? AppTheme.statusWarning : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLocalMonitoring)
                    const Text(
                      'Tanpa Akun • Hanya Telemetri Emergency MQTT',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    )
                  else if (project != null)
                    Text(
                      project.name,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  if (!isLocalMonitoring && project != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            project.location,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu List
            _ProfileMenuItem(
              icon: Icons.info_outline_rounded,
              label: 'Tentang',
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.settings_ethernet_rounded,
              label: 'Pengaturan Koneksi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectionSetupPage(isEditing: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (isLocalMonitoring)
              _ProfileMenuItem(
                icon: Icons.login_rounded,
                label: 'Masuk Akun Operator (Sign in)',
                isDestructive: false,
                onTap: () => ref.read(authProvider.notifier).switchToLogin(),
              )
            else
              _ProfileMenuItem(
                icon: Icons.logout_rounded,
                label: 'Keluar',
                isDestructive: true,
                onTap: () => _showLogoutDialog(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: const Text('Tentang Aplikasi'),
        content: const Text(
          'NiceGas BioCNG Monitoring\nVersi 1.0.0\n\nDikembangkan oleh CoreSight untuk pemantauan sistem produksi BioCNG secara real-time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari sesi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.statusCritical),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppTheme.statusCritical : AppTheme.textPrimary;

    return _AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDestructive
              ? AppTheme.statusCritical.withValues(alpha: 0.5)
              : AppTheme.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _AppCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}
