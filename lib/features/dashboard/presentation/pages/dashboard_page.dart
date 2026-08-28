import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data_controller.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_charts.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/alert_model.dart';
import '../../../../shared/models/telemetry_model.dart';
import '../../../shell/main_shell_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/sub_header.dart';
import '../../../telemetry/presentation/pages/telemetry_history_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedNodeIndex = 0;
  final List<String> _nodeLabels = ['Node 1: Biodigester','Node 2: Purifikasi','Node 3: Kompresi'];

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(selectedProjectProvider);
    if (project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    if (AppConfig.isDemoMode) {
      final summary = ref.watch(demoDashboardProvider);
      return _buildScaffold(context, ref, project, AsyncValue.data(summary));
    }
    final summaryAsync = ref.watch(dashboardDataProvider);
    return _buildScaffold(context, ref, project, summaryAsync);
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, ProjectModel project, AsyncValue<DashboardSummary> summaryAsync) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const SubHeader(title: 'Dashboard'),
      body: summaryAsync.when(
        data: (summary) => _buildBody(context, ref, project, summary),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, _) => _buildError(ref, err.toString()),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectModel project, DashboardSummary summary) {
    final demoState = AppConfig.isDemoMode ? ref.watch(demoDataControllerProvider) : null;
    return Stack(
      children: [
        RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => ref.refresh(dashboardDataProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (summary.criticalAlerts > 0 || summary.warningAlerts > 0) _AlertBanner(summary: summary),
                if (summary.criticalAlerts > 0 || summary.warningAlerts > 0) const SizedBox(height: 12),
                _SystemStatusCard(summary: summary),
                const SizedBox(height: 12),
                if (demoState != null) ...[
                  DashboardChartsSection(demoState: demoState, onlineDevices: summary.onlineDevices, offlineDevices: summary.offlineDevices, totalDevices: summary.totalDevices),
                  const SizedBox(height: 4),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _DeviceStatusSmallCard(summary: summary)),
                    const SizedBox(width: 10),
                    Expanded(child: _AiGreetingBar(onTap: () => ref.read(shellTabProvider.notifier).state = 1, summary: summary)),
                  ],
                ),
                const SizedBox(height: 12),
                _DigitalTwinExplorer(summary: summary, selectedNodeIndex: _selectedNodeIndex, nodeLabels: _nodeLabels, onNodeSelected: (i) => setState(() => _selectedNodeIndex = i)),
                const SizedBox(height: 12),
                _RiwayatLog(alerts: summary.recentAlerts),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
            const Icon(Icons.error_outline, color: AppTheme.statusCritical, size: 48),
            const SizedBox(height: 12),
            const Text('Gagal memuat data', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.invalidate(dashboardDataProvider), child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final DashboardSummary summary;
  const _AlertBanner({required this.summary});
  @override
  Widget build(BuildContext context) {
    final isCritical = summary.criticalAlerts > 0;
    final color = isCritical ? AppTheme.statusCritical : AppTheme.statusWarning;
    final message = summary.recentAlerts.isNotEmpty ? summary.recentAlerts.first.message : (isCritical ? 'Ada gangguan kritis!' : 'Perlu diperiksa');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.cardRadius), border: Border.all(color: AppTheme.borderColor), boxShadow: [BoxShadow(color: color, offset: const Offset(-3, 0))]),
      child: Row(
        children: [
          Icon(isCritical ? Icons.warning_rounded : Icons.info_outline_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isCritical ? 'CRITICAL ALERT' : 'SYSTEM WARNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(message, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
        ],
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  final DashboardSummary summary;
  const _SystemStatusCard({required this.summary});
  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolveStatus(summary);
    final lastUpdate = summary.latestTelemetry.isNotEmpty ? _relativeTime(summary.latestTelemetry.first.timestamp) : 'Baru saja';
    return _AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MAIN SYSTEM STATUS', style: TextStyle(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w700, color: AppTheme.textSecondary.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(summary.criticalAlerts > 0 ? Icons.cancel : summary.warningAlerts > 0 ? Icons.error : Icons.check_circle, color: color, size: 18),
                const SizedBox(width: 6),
                Text(label.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text('LAST UPDATED: $lastUpdate', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ])),
        ],
      ),
    );
  }
  static (String, Color) _resolveStatus(DashboardSummary s) {
    if (s.criticalAlerts > 0) return ('Critical Failure', AppTheme.statusCritical);
    if (s.warningAlerts > 0) return ('Warning Active', AppTheme.statusWarning);
    return ('Optimal', AppTheme.statusOptimal);
  }
}

class _DeviceStatusSmallCard extends StatelessWidget {
  final DashboardSummary summary;
  const _DeviceStatusSmallCard({required this.summary});
  @override
  Widget build(BuildContext context) {
    final total = summary.totalDevices;
    final online = summary.onlineDevices;
    final offline = summary.offlineDevices;
    return _AppCard(
      child: Row(children: [
        SizedBox(width: 56, height: 56,
          child: total == 0 ? const Center(child: Icon(Icons.devices_rounded, color: AppTheme.textSecondary, size: 28)) : _MiniDonut(online: online, offline: offline, total: total)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Status Perangkat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('${total > 0 ? (online / total * 100).round() : 0}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const Text('Online', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          _LegendDot(color: AppTheme.statusOptimal, label: 'Online: $online'),
          const SizedBox(height: 2),
          _LegendDot(color: AppTheme.statusCritical, label: 'Offline: $offline'),
        ])),
      ]),
    );
  }
}

class _MiniDonut extends StatelessWidget {
  final int online; final int offline; final int total;
  const _MiniDonut({required this.online, required this.offline, required this.total});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DonutPainter(onlineFrac: total > 0 ? online / total : 0.0));
}

class _DonutPainter extends CustomPainter {
  final double onlineFrac;
  _DonutPainter({required this.onlineFrac});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, Paint()..color = AppTheme.statusCritical.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 9.0..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.2832 * onlineFrac, false,
      Paint()..color = AppTheme.statusOptimal..style = PaintingStyle.stroke..strokeWidth = 9.0..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_DonutPainter old) => old.onlineFrac != onlineFrac;
}

class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
  ]);
}

class _AiGreetingBar extends StatelessWidget {
  final VoidCallback onTap;
  final DashboardSummary summary;
  const _AiGreetingBar({required this.onTap, required this.summary});
  @override
  Widget build(BuildContext context) {
    final statusText = summary.criticalAlerts > 0 ? 'Perlu perhatian segera!' : summary.warningAlerts > 0 ? 'Ada peringatan aktif.' : 'Sistem sedang optimal.';
    return GestureDetector(
      onTap: onTap,
      child: _AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.statusOptimal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.statusOptimal, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI ASSISTANT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(statusText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }
}

class _DigitalTwinExplorer extends StatelessWidget {
  final DashboardSummary summary;
  final int selectedNodeIndex;
  final List<String> nodeLabels;
  final ValueChanged<int> onNodeSelected;
  const _DigitalTwinExplorer({required this.summary, required this.selectedNodeIndex, required this.nodeLabels, required this.onNodeSelected});
  @override
  Widget build(BuildContext context) {
    final telemetry = summary.latestTelemetry.isNotEmpty ? (selectedNodeIndex < summary.latestTelemetry.length ? summary.latestTelemetry[selectedNodeIndex] : summary.latestTelemetry.first) : null;
    final nodeKeywords = ['biodigester', 'purifikasi', 'kompresi'];
    final keyword = nodeKeywords[selectedNodeIndex];
    TelemetryModel? matchedTelemetry;
    for (final t in summary.latestTelemetry) {
      if ((t.component ?? '').toLowerCase().contains(keyword)) { matchedTelemetry = t; break; }
    }
    matchedTelemetry ??= telemetry;
    return _AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text('PROCESS PIPELINE (DIGITAL TWIN)', style: TextStyle(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
        SizedBox(height: 36, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: nodeLabels.length,
          separatorBuilder: (_, __) => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_right_alt_rounded, color: AppTheme.borderColor, size: 20)),
          itemBuilder: (context, i) {
            final selected = i == selectedNodeIndex;
            return GestureDetector(
              onTap: () => onNodeSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: selected ? AppTheme.primary : AppTheme.borderColor),
                ),
                child: Center(child: Text(nodeLabels[i].split(':').last.trim().toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary))),
              ),
            );
          },
        )),
        const SizedBox(height: 16),
        Container(height: 120, margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.borderColor)),
          child: const Center(child: Text('[3D Asset Placeholder]', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)))),
        const SizedBox(height: 12),
        if (matchedTelemetry != null && matchedTelemetry.metrics.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...matchedTelemetry.metrics.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    final devId = matchedTelemetry?.deviceId;
                    if (devId != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TelemetryHistoryPage(deviceId: devId),
                      ));
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.primary),
                        ],
                      ),
                      Text('${e.value.value.toStringAsFixed(1)} ${e.value.unit}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ]),
                  ),
                ),
              )),
            ]))
        else
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tidak ada data metrik untuk node ini.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _NodeStatusRow(status: matchedTelemetry?.status ?? 'unknown')),
      ]),
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
    if (s == 'optimal' || s == 'online' || s == 'normal') { color = AppTheme.statusOptimal; label = 'Node Status: Optimal'; }
    else if (s == 'warning') { color = AppTheme.statusWarning; label = 'Node Status: Peringatan'; }
    else if (s == 'critical' || s == 'offline') { color = AppTheme.statusCritical; label = 'Node Status: Kritis'; }
    else { color = AppTheme.textSecondary; label = 'Node Status: '; }
    return Row(children: [
      Icon(Icons.circle, size: 10, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    ]);
  }
}

class _RiwayatLog extends StatelessWidget {
  final List<AlertModel> alerts;
  const _RiwayatLog({required this.alerts});
  @override
  Widget build(BuildContext context) {
    final shown = alerts.take(4).toList();
    return _AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('SYSTEM LOGS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.0, color: AppTheme.textSecondary)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsPage())),
              child: const Text('VIEW ALL', style: TextStyle(fontSize: 10, letterSpacing: 0.5, color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        if (shown.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No active logs.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center))
        else
          ...shown.map((alert) => _LogItem(alert: alert)),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _LogItem extends StatelessWidget {
  final AlertModel alert;
  const _LogItem({required this.alert});
  @override
  Widget build(BuildContext context) {
    final sev = alert.severity.toUpperCase();
    final color = sev == 'CRITICAL' ? AppTheme.statusCritical : sev == 'WARNING' ? AppTheme.statusWarning : AppTheme.textSecondary;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderColor, width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 45, child: Text(_relativeTime(alert.timestamp), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textSecondary))),
        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4, right: 12), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(alert.component.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ])),
      ]),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}



String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
