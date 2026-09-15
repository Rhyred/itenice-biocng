import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/widgets/sub_header.dart';
import '../controllers/tts_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE LOKAL CHAT
// ══════════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        time = DateTime.now();
}

/// State lokal chat (tidak perlu provider global — sesuai PRD §3.3)
class _AiChatNotifier extends StateNotifier<List<_ChatMessage>> {
  _AiChatNotifier() : super([
    _ChatMessage(
      text: 'Halo! Ada yang ingin ditanyakan mengenai pemeliharaan dan performa mesin hari ini?',
      isUser: false,
    ),
  ]);

  void sendMessage(String text) {
    state = [...state, _ChatMessage(text: text, isUser: true)];

    final reply = _generateMockReply(text);
    Future.delayed(const Duration(milliseconds: 600), () {
      state = [...state, _ChatMessage(text: reply, isUser: false)];
    });
  }

  static String _generateMockReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('filter') || lower.contains('scrubber')) {
      return 'Filter Scrubber saat ini pada kondisi 15%. Disarankan segera dipesan untuk penggantian dalam 5 hari.';
    } else if (lower.contains('efisiensi') || lower.contains('tren')) {
      return 'Efisiensi produksi BioCNG minggu ini rata-rata 87%. Tren stabil dengan sedikit penurunan di hari ke-3.';
    } else if (lower.contains('kompresor') || lower.contains('kompresi')) {
      return 'Kompresor Utama dalam kondisi AMAN (85%). Tidak ada tindakan mendesak diperlukan saat ini.';
    } else if (lower.contains('status') || lower.contains('produksi')) {
      return 'Sistem beroperasi normal. Semua node aktif dan metrik dalam batas toleransi.';
    }
    return 'Permintaan Anda sedang diproses. Silakan hubungi tim teknis untuk informasi lebih lanjut.';
  }
}

final _aiChatProvider =
    StateNotifierProvider.autoDispose<_AiChatNotifier, List<_ChatMessage>>(
        (_) => _AiChatNotifier());

// ══════════════════════════════════════════════════════════════════════════════
// HALAMAN PEMELIHARAAN AI
// ══════════════════════════════════════════════════════════════════════════════

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isListening = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    ref.read(_aiChatProvider.notifier).sendMessage(text.trim());
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TtsState>(ttsProvider, (previous, next) {
      if (next.status == TtsStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    final summaryAsync = ref.watch(dashboardDataProvider);
    final messages = ref.watch(_aiChatProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: const SubHeader(title: 'Pemeliharaan AI'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Machine Health Score
                    summaryAsync.when(
                      data: (s) => _MachineHealthCard(summary: s),
                      loading: () => const _CardShimmer(height: 110),
                      error: (_, st) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),

                    // 2. Prediksi Suku Cadang
                    const _PrediksiSukuCadangSection(),
                    const SizedBox(height: 12),

                    // 3. Panel Chat AI
                    _ChatPanel(
                      messages: messages,
                      scrollController: _scrollCtrl,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Input row with dynamic bottom inset handling
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: _ChatInputRow(
                controller: _inputCtrl,
                isListening: _isListening,
                onSend: _sendMessage,
                onMicTap: () {
                  setState(() => _isListening = !_isListening);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isListening
                          ? 'Mendengarkan... (fitur STT akan tersedia di iterasi berikutnya)'
                          : 'Mic dimatikan'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onQuickReply: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Machine Health Score
class _MachineHealthCard extends StatelessWidget {
  final DashboardSummary summary;

  const _MachineHealthCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final score =
        (100 - (summary.criticalAlerts * 20) - (summary.warningAlerts * 8))
            .clamp(0, 100);

    final (label, color) = score >= 80
        ? ('Sehat', AppTheme.statusOptimal)
        : score >= 50
            ? ('Perlu Perhatian', AppTheme.statusWarning)
            : ('Kritis', AppTheme.statusCritical);

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MACHINE HEALTH SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusBadge(label: label, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.monitor_heart_outlined,
                  color: color.withValues(alpha: 0.6), size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    score >= 80
                        ? 'Sistem optimal. Cek filter scrubber dalam 120 jam.'
                        : score >= 50
                            ? 'Perlu perhatian. Periksa komponen yang bermasalah.'
                            : 'Kondisi kritis! Segera hubungi tim teknis.',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '* Nilai ini adalah estimasi berdasarkan telemetry aktif.',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Prediksi Suku Cadang
class _PrediksiSukuCadangSection extends StatelessWidget {
  const _PrediksiSukuCadangSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Prediksi Suku Cadang',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SukuCadangCard(
                nama: 'Filter Scrubber',
                persentase: 15,
                isCritical: true,
                keterangan: 'Ganti 5 hari',
                onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur pemesanan akan segera tersedia.')),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SukuCadangCard(
                nama: 'Kompresor Utama',
                persentase: 85,
                isCritical: false,
                keterangan: 'Kondisi baik',
                onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Jadwal servis berhasil dibuat.')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SukuCadangCard extends StatelessWidget {
  final String nama;
  final int persentase;
  final bool isCritical;
  final String keterangan;
  final VoidCallback onAction;

  const _SukuCadangCard({
    required this.nama,
    required this.persentase,
    required this.isCritical,
    required this.keterangan,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCritical ? AppTheme.statusCritical : AppTheme.statusOptimal;

    return _AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$persentase%',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              _StatusBadge(
                label: isCritical ? 'KRITIS' : 'AMAN',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            nama,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            keterangan,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: persentase / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCritical ? AppTheme.statusCritical : AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCritical
                        ? Icons.shopping_cart_outlined
                        : Icons.build_outlined,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCritical ? 'Pesan' : 'Servis',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel Chat AI
class _ChatPanel extends StatelessWidget {
  final List<_ChatMessage> messages;
  final ScrollController scrollController;

  const _ChatPanel(
      {required this.messages, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Asisten AI BioCNG NiceGas',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusOptimal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusOptimal),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bubble Chat
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: messages
                  .map((msg) => _ChatBubble(message: msg))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedTime =
        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}';
    final ttsState = ref.watch(ttsProvider);
    final isSpeakingThisMessage = ttsState.status == TtsStatus.speaking &&
        ttsState.activeMessageId == message.id;

    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.primary
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser
              ? null
              : Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 13,
                color: message.isUser ? Colors.white : AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: message.isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: message.isUser
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppTheme.textSecondary,
                  ),
                ),
                if (!message.isUser) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    key: ValueKey('tts_button_${message.id}'),
                    onTap: () {
                      if (isSpeakingThisMessage) {
                        ref.read(ttsProvider.notifier).stop();
                      } else {
                        ref.read(ttsProvider.notifier).speak(
                              messageId: message.id,
                              text: message.text,
                            );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSpeakingThisMessage
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                            size: 14,
                            color: isSpeakingThisMessage
                                ? AppTheme.statusCritical
                                : AppTheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isSpeakingThisMessage ? 'Stop' : 'Read',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSpeakingThisMessage
                                  ? AppTheme.statusCritical
                                  : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Input row chat
class _ChatInputRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final ValueChanged<String> onSend;
  final VoidCallback onMicTap;
  final ValueChanged<String> onQuickReply;

  const _ChatInputRow({
    required this.controller,
    required this.isListening,
    required this.onSend,
    required this.onMicTap,
    required this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick reply chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Estimasi filter?',
                'Tren efisiensi?',
                'Status kompresor?',
              ]
                  .map((q) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => onQuickReply(q),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(18),
                              color: AppTheme.surface,
                            ),
                            child: Text(
                              q,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Text field + buttons
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Tanya Asisten AI...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: onSend,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.send_rounded,
                color: AppTheme.primary,
                onTap: () => onSend(controller.text),
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: isListening
                    ? AppTheme.statusCritical
                    : AppTheme.textSecondary,
                onTap: onMicTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _AppCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  final double height;

  const _CardShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.borderColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
    );
  }
}
