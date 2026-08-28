import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../providers/dashboard_provider.dart';
import '../../../devices/presentation/pages/device_list_page.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../telemetry/presentation/pages/telemetry_history_page.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../../../shell/main_shell_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // State lokal untuk tab Digital Twin Explorer
  int _selectedNodeIndex = 0;

  final List<String> _nodeLabels = [
    'Node 1: Biodigester',
    'Node 2: Purifikasi',
    'Node 3: Kompresi',
  ];

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(selectedProjectProvider);

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // Demo mode: gunakan Provider sinkron agar tidak ada flickering
    // Production: gunakan FutureProvider yang fetch dari API
    if (AppConfig.isDemoMode) {
      final summary = ref.watch(demoDashboardProvider);
      return _buildScaffold(context, ref, project,
          AsyncValue.data(summary));
    }

    final summaryAsync = ref.watch(dashboardDataProvider);
    return _buildScaffold(context, ref, project, summaryAsync);
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
    AsyncValue<DashboardSummary> summaryAsync,
  ) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsPage()),
            ),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => _buildBody(context, ref, project, summary),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, _) => _buildError(ref, err.toString()),
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
    DashboardSummary summary,
  ) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardDataProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Banner Peringatan
                if (summary.criticalAlerts > 0 || summary.warningAlerts > 0)
                  _AlertBanner(summary: summary),

                if (summary.criticalAlerts > 0 || summary.warningAlerts > 0)
                  const SizedBox(height: 12),

                // 2. Status Sistem Utama
                _SystemStatusCard(summary: summary),
                const SizedBox(height: 12),

                // 3. AI Greeting Bar
                _AiGreetingBar(
                  onTap: () =>
                      ref.read(shellTabProvider.notifier).state = 1,
                  summary: summary,
                ),
                const SizedBox(height: 12),

                // 4. Sensor Node Digital Twin Explorer
                _DigitalTwinExplorer(
                  summary: summary,
                  selectedNodeIndex: _selectedNodeIndex,
                  nodeLabels: _nodeLabels,
                  onNodeSelected: (i) =>
                      setState(() => _selectedNodeIndex = i),
                ),
                const SizedBox(height: 12),

                // 5. Riwayat Log
                _RiwayatLog(alerts: summary.recentAlerts),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // 6. Mic Input Bar (floating)
        _MicInputBar(
          onTap: () => ref.read(shellTabProvider.notifier).state = 1,
        ),
      ],
    );
  }


  Widget _buildError(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.statusCritical, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(dashboardDataProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// KOMPONEN-KOMPONEN DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════

/// 1. Banner Peringatan
class _AlertBanner extends StatelessWidget {
  final DashboardSummary summary;

  const _AlertBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isCritical = summary.criticalAlerts > 0;
    final color =
        isCritical ? AppTheme.statusCritical : AppTheme.statusWarning;
    final bgColor = color.withValues(alpha: 0.08);
    final message = summary.recentAlerts.isNotEmpty
        ? summary.recentAlerts.first.message
        : (isCritical ? 'Ada gangguan kritis!' : 'Perlu diperiksa');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical
                      ? 'NOTIFIKASI PERINGATAN KRITIS'
                      : 'NOTIFIKASI PERINGATAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                      fontSize: 13,
                      color: color.withValues(alpha: 0.85)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Status Sistem Utama
class _SystemStatusCard extends StatelessWidget {
  final DashboardSummary summary;

  const _SystemStatusCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolveStatus(summary);
    final lastUpdate = summary.latestTelemetry.isNotEmpty
        ? _relativeTime(summary.latestTelemetry.first.timestamp)
        : 'Baru saja';

    return _AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS SISTEM UTAMA',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Terakhir diperbarui: $lastUpdate',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              summary.criticalAlerts > 0
                  ? Icons.warning_amber_rounded
                  : summary.warningAlerts > 0
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_outline_rounded,
              color: color,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  static (String, Color) _resolveStatus(DashboardSummary s) {
    if (s.criticalAlerts > 0) {
      return ('Ada Gangguan Kritis', AppTheme.statusCritical);
    } else if (s.warningAlerts > 0) {
      return ('Perlu Diperiksa', AppTheme.statusWarning);
    }
    return ('Operasi Normal', AppTheme.statusOptimal);
  }
}

/// 3. AI Greeting Bar
class _AiGreetingBar extends StatelessWidget {
  final VoidCallback onTap;
  final DashboardSummary summary;

  const _AiGreetingBar({required this.onTap, required this.summary});

  @override
  Widget build(BuildContext context) {
    final statusText = summary.criticalAlerts > 0
        ? 'Perlu perhatian segera!'
        : summary.warningAlerts > 0
            ? 'Ada peringatan aktif.'
            : 'Sistem sedang optimal.';

    return GestureDetector(
      onTap: onTap,
      child: _AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halo, Saya AI Kamu!',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(statusText,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 4. Sensor Node Digital Twin Explorer
class _DigitalTwinExplorer extends StatelessWidget {
  final DashboardSummary summary;
  final int selectedNodeIndex;
  final List<String> nodeLabels;
  final ValueChanged<int> onNodeSelected;

  const _DigitalTwinExplorer({
    required this.summary,
    required this.selectedNodeIndex,
    required this.nodeLabels,
    required this.onNodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil telemetry sesuai node (index fallback)
    final telemetry = summary.latestTelemetry.isNotEmpty
        ? (selectedNodeIndex < summary.latestTelemetry.length
            ? summary.latestTelemetry[selectedNodeIndex]
            : summary.latestTelemetry.first)
        : null;

    // Resolve status node
    final nodeKeywords = ['biodigester', 'purifikasi', 'kompresi'];
    final keyword = nodeKeywords[selectedNodeIndex];

    // Coba cari telemetry yang cocok dengan keyword
    TelemetryModel? matchedTelemetry;
    for (final t in summary.latestTelemetry) {
      final comp = (t.component ?? '').toLowerCase();
      if (comp.contains(keyword)) {
        matchedTelemetry = t;
        break;
      }
    }
    matchedTelemetry ??= telemetry;

    return _AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'SENSOR NODE DIGITAL TWIN EXPLORER',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          // Tab Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nodeLabels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == selectedNodeIndex;
                return GestureDetector(
                  onTap: () => onNodeSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Text(
                      nodeLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Area Digital Twin (KOSONGKAN — aset belum tersedia) ─────────────
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            // TODO: masukkan gambar/render 3D digital twin node [nama node] di sini
            // Contoh ketika aset sudah tersedia:
            // child: Image.asset('assets/images/twin_${nodeLabels[selectedNodeIndex].toLowerCase().replaceAll(' ', '_')}.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),

          // ── Metrik Dinamis ──────────────────────────────────────────────────
          if (matchedTelemetry != null && matchedTelemetry.metrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...matchedTelemetry.metrics.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                            ),
                            Text(
                              '${e.value.value % 1 == 0 ? e.value.value.toInt() : e.value.value.toStringAsFixed(1)} ${e.value.unit}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tidak ada data metrik untuk node ini.',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),

          const SizedBox(height: 10),

          // ── Status Node ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _NodeStatusRow(
              status: matchedTelemetry?.status ?? 'unknown',
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeStatusRow extends StatelessWidget {
  final String status;

  const _NodeStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final Color color;
    final String label;

    if (s == 'optimal' || s == 'online' || s == 'normal') {
      color = AppTheme.statusOptimal;
      label = 'Node Status: Optimal';
    } else if (s == 'warning') {
      color = AppTheme.statusWarning;
      label = 'Node Status: Peringatan';
    } else if (s == 'critical' || s == 'offline') {
      color = AppTheme.statusCritical;
      label = 'Node Status: Kritis';
    } else {
      color = AppTheme.textSecondary;
      label = 'Node Status: $status';
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color)),
      ],
    );
  }
}

/// 5. Riwayat Log
class _RiwayatLog extends StatelessWidget {
  final List<AlertModel> alerts;

  const _RiwayatLog({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final shown = alerts.take(3).toList();

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Log',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textPrimary),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Tidak ada log terkini.',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...shown.map((alert) => _LogItem(alert: alert)),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final AlertModel alert;

  const _LogItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final sev = alert.severity.toUpperCase();
    final color = sev == 'CRITICAL'
        ? AppTheme.statusCritical
        : sev == 'WARNING'
            ? AppTheme.statusWarning
            : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sev == 'CRITICAL'
                  ? Icons.warning_rounded
                  : sev == 'WARNING'
                      ? Icons.info_outline_rounded
                      : Icons.bolt_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  alert.component,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            _relativeTime(alert.timestamp),
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// 6. Mic Input Bar (floating pill di bawah)
class _MicInputBar extends StatelessWidget {
  final VoidCallback onTap;

  const _MicInputBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 40,
      right: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D29),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"Tanya status produksi..."',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
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

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ══════════════════════════════════════════════════════════════════════════════

/// Kartu dasar dengan border dan radius sesuai design token
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

/// Drawer menu item
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}

/// Format waktu relatif
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
