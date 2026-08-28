import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';

class GlobalHeader extends ConsumerWidget implements PreferredSizeWidget {
  const GlobalHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);
    final projectName = project?.name ?? 'Bio-CNG Plant Alpha';

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1.0)),
      ),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/icons/app_logo.png', width: 28, height: 28, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.energy_savings_leaf, color: AppTheme.primary, size: 28),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    projectName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppTheme.statusOptimal),
                      SizedBox(width: 4),
                      Text('System Online', style: TextStyle(color: AppTheme.statusOptimal, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary, size: 24),
                Positioned(
                  top: -2, right: -2,
                  child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppTheme.statusWarning, shape: BoxShape.circle)),
                ),
              ]),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsPage())),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
