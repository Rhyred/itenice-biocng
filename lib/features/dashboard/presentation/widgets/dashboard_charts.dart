import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/models/telemetry_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Breakpoint helper
// ─────────────────────────────────────────────────────────────────────────────
bool _isMobile(double width) => width < 600;

// ─────────────────────────────────────────────────────────────────────────────
// Section header helper
// ─────────────────────────────────────────────────────────────────────────────
class ChartSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ChartSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final Widget child;

  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Telemetry Trend Chart (Line)
// ─────────────────────────────────────────────────────────────────────────────
class TelemetryTrendChart extends StatelessWidget {
  final List<TelemetryModel> history;
  final String metricKey;
  final String unit;
  final Color color;
  final String title;
  final double minY;
  final double maxY;
  final bool isLive;

  const TelemetryTrendChart({
    super.key,
    required this.history,
    required this.metricKey,
    required this.unit,
    required this.color,
    required this.title,
    required this.minY,
    required this.maxY,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = history.reversed
        .where((t) => t.metrics.containsKey(metricKey))
        .take(15)
        .toList()
        .reversed
        .toList();

    if (data.isEmpty) {
      return _ChartCard(
        child: SizedBox(
          height: 130,
          child: Center(
            child: Text(title,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ),
      );
    }

    final spots = List.generate(data.length, (i) {
      final val = data[i].metrics[metricKey]?.value ?? 0.0;
      return FlSpot(i.toDouble(), val);
    });

    final currentVal = spots.last.y;

    return _ChartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                    if (isLive || AppConfig.isDemoMode) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.statusCritical,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${currentVal.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 8, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1C1A18),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(2)} $unit',
                              TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, idx) =>
                          FlDotCirclePainter(
                        radius: idx == spots.length - 1 ? 3.5 : 0,
                        color: color,
                        strokeWidth: 1.5,
                        strokeColor: AppTheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Gas Flow Bar Chart
// ─────────────────────────────────────────────────────────────────────────────
class GasFlowBarChart extends StatelessWidget {
  final List<TelemetryModel> history;
  final bool isLive;

  const GasFlowBarChart({super.key, required this.history, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    final data = history.reversed
        .where((t) => t.metrics.containsKey('gas_flow'))
        .take(12)
        .toList()
        .reversed
        .toList();

    if (data.isEmpty) return const SizedBox.shrink();

    final currentFlow =
        data.last.metrics['gas_flow']?.value.toStringAsFixed(1) ?? '—';

    final groups = List.generate(data.length, (i) {
      final val = data[i].metrics['gas_flow']?.value ?? 0.0;
      final isLast = i == data.length - 1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            color: isLast
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.3),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return _ChartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Laju Produksi Gas',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  if (isLive || AppConfig.isDemoMode) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.statusCritical,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$currentFlow Nm³/h',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                maxY: 30,
                minY: 18,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppTheme.borderColor, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 3,
                      getTitlesWidget: _leftTitle,
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: groups,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1C1A18),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)} Nm³/h',
                      const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _leftTitle(double v, TitleMeta _) => Text(
        v.toInt().toString(),
        style:
            const TextStyle(fontSize: 8, color: AppTheme.textSecondary),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Device Status Donut Chart
// ─────────────────────────────────────────────────────────────────────────────
class DeviceStatusDonut extends StatelessWidget {
  final int online;
  final int offline;
  final int total;

  const DeviceStatusDonut({
    super.key,
    required this.online,
    required this.offline,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final pct = total > 0 ? (online / total * 100).round() : 0;

    return _ChartCard(
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 26,
                sections: [
                  PieChartSectionData(
                    value: online.toDouble(),
                    color: AppTheme.statusOptimal,
                    radius: 18,
                    showTitle: false,
                  ),
                  if (offline > 0)
                    PieChartSectionData(
                      value: offline.toDouble(),
                      color: AppTheme.statusCritical,
                      radius: 18,
                      showTitle: false,
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Perangkat',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  '$pct%\nOnline',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                _Legend(
                    color: AppTheme.statusOptimal, label: 'Online: $online'),
                const SizedBox(height: 3),
                _Legend(
                    color: AppTheme.statusCritical,
                    label: 'Offline: $offline'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Dashboard Charts Section — RESPONSIVE (mobile single col, tablet 2-col)
// ─────────────────────────────────────────────────────────────────────────────
class DashboardChartsSection extends StatelessWidget {
  final List<TelemetryModel> history;
  final int onlineDevices;
  final int offlineDevices;
  final int totalDevices;
  final bool isLive;

  const DashboardChartsSection({
    super.key,
    required this.history,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.totalDevices,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = _isMobile(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ChartSectionHeader(
              title: 'Monitoring Real-Time',
              subtitle: 'Update setiap 2 detik dari sensor lapangan',
              icon: Icons.show_chart_rounded,
            ),

            // Tekanan + Metana
            if (mobile) ...[
              TelemetryTrendChart(
                history: history,
                metricKey: 'pressure',
                unit: 'bar',
                color: AppTheme.statusWarning,
                title: 'Tekanan Gas',
                minY: 1.0,
                maxY: 1.8,
                isLive: isLive,
              ),
              const SizedBox(height: 10),
              TelemetryTrendChart(
                history: history,
                metricKey: 'methane',
                unit: '%',
                color: AppTheme.statusOptimal,
                title: 'Kadar Metana',
                minY: 55,
                maxY: 70,
                isLive: isLive,
              ),
              const SizedBox(height: 10),
              TelemetryTrendChart(
                history: history,
                metricKey: 'temperature',
                unit: '°C',
                color: AppTheme.primary,
                title: 'Suhu Digester',
                minY: 35,
                maxY: 42,
                isLive: isLive,
              ),
              const SizedBox(height: 10),
              DeviceStatusDonut(
                online: onlineDevices,
                offline: offlineDevices,
                total: totalDevices,
              ),
            ] else ...[
              // 2-column layout for tablet/desktop
              Row(
                children: [
                  Expanded(
                    child: TelemetryTrendChart(
                      history: history,
                      metricKey: 'pressure',
                      unit: 'bar',
                      color: AppTheme.statusWarning,
                      title: 'Tekanan Gas',
                      minY: 1.0,
                      maxY: 1.8,
                      isLive: isLive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TelemetryTrendChart(
                      history: history,
                      metricKey: 'methane',
                      unit: '%',
                      color: AppTheme.statusOptimal,
                      title: 'Kadar Metana',
                      minY: 55,
                      maxY: 70,
                      isLive: isLive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TelemetryTrendChart(
                      history: history,
                      metricKey: 'temperature',
                      unit: '°C',
                      color: AppTheme.primary,
                      title: 'Suhu Digester',
                      minY: 35,
                      maxY: 42,
                      isLive: isLive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DeviceStatusDonut(
                      online: onlineDevices,
                      offline: offlineDevices,
                      total: totalDevices,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            // Gas Flow full width di semua ukuran
            GasFlowBarChart(history: history, isLive: isLive),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}
