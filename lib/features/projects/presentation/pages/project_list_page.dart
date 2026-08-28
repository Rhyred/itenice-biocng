import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../../../../shared/models/project_model.dart';
import '../../../shell/main_shell_page.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

/// A page displaying the list of NICEGAS projects.
class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NiceGas BioCNG'),
        actions: [
          if (AppConfig.isDemoMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.statusOptimal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.statusOptimal.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: AppTheme.statusOptimal, size: 8),
                  SizedBox(width: 5),
                  Text(
                    'DEMO',
                    style: TextStyle(
                      color: AppTheme.statusOptimal,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(projectProvider.future),
        child: projectsAsync.when(
          data: (response) => response.data.isEmpty
              ? _EmptyState(onRetry: () => ref.invalidate(projectProvider))
              : _ProjectList(projects: response.data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _ErrorState(
            error: err.toString(),
            onRetry: () => ref.invalidate(projectProvider),
          ),
        ),
      ),
    );
  }
}

class _ProjectList extends ConsumerWidget {
  final List<ProjectModel> projects;

  const _ProjectList({required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final project = projects[index];
        return GestureDetector(
          onTap: () {
            ref.read(selectedProjectProvider.notifier).state = project;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MainShellPage(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.factory_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              project.location,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No projects available.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Check Again'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load projects',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
