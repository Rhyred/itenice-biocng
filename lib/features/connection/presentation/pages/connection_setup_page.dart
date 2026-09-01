import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/config/runtime_config.dart';
import '../../../../core/config/runtime_config_store.dart';
import '../../../../core/mqtt/mqtt_provider.dart';
import '../../../../core/mqtt/mqtt_service.dart';
import '../../../../core/theme/app_theme.dart';

enum TestState { idle, testing, success, failed }

class ConnectionSetupPage extends ConsumerStatefulWidget {
  final bool isEditing;

  const ConnectionSetupPage({super.key, this.isEditing = false});

  @override
  ConsumerState<ConnectionSetupPage> createState() =>
      _ConnectionSetupPageState();
}

class _ConnectionSetupPageState extends ConsumerState<ConnectionSetupPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _apiUrlCtrl;
  late TextEditingController _mqttPrimaryHostCtrl;
  late TextEditingController _mqttPrimaryPortCtrl;
  late TextEditingController _mqttPrimaryUserCtrl;
  late TextEditingController _mqttPrimaryPassCtrl;
  late TextEditingController _mqttEmergencyHostCtrl;
  late TextEditingController _mqttEmergencyPortCtrl;
  late TextEditingController _mqttEmergencyUserCtrl;
  late TextEditingController _mqttEmergencyPassCtrl;
  late TextEditingController _siteIdCtrl;
  late TextEditingController _plantNameCtrl;

  TestState _apiTestState = TestState.idle;
  String? _apiTestMessage;

  TestState _mqttTestState = TestState.idle;
  String? _mqttTestMessage;

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(runtimeConfigProvider);

    _apiUrlCtrl =
        TextEditingController(text: currentConfig.effectiveApiBaseUrl);
    _mqttPrimaryHostCtrl =
        TextEditingController(text: currentConfig.effectiveMqttPrimaryHost);
    _mqttPrimaryPortCtrl = TextEditingController(
        text: currentConfig.effectiveMqttPrimaryPort.toString());
    _mqttPrimaryUserCtrl =
        TextEditingController(text: currentConfig.effectiveMqttPrimaryUsername);
    _mqttPrimaryPassCtrl =
        TextEditingController(text: currentConfig.effectiveMqttPrimaryPassword);
    _mqttEmergencyHostCtrl = TextEditingController(
        text: currentConfig.mqttEmergencyHost.isNotEmpty
            ? currentConfig.mqttEmergencyHost
            : '');
    _mqttEmergencyPortCtrl = TextEditingController(
        text: currentConfig.mqttEmergencyPort > 0
            ? currentConfig.mqttEmergencyPort.toString()
            : '1883');
    _mqttEmergencyUserCtrl =
        TextEditingController(text: currentConfig.effectiveMqttEmergencyUsername);
    _mqttEmergencyPassCtrl =
        TextEditingController(text: currentConfig.effectiveMqttEmergencyPassword);
    _siteIdCtrl = TextEditingController(
        text: currentConfig.siteId.isNotEmpty ? currentConfig.siteId : 'plant-alpha');
    _plantNameCtrl = TextEditingController(
        text: currentConfig.plantName.isNotEmpty ? currentConfig.plantName : 'Bio-CNG Plant Alpha');
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    _mqttPrimaryHostCtrl.dispose();
    _mqttPrimaryPortCtrl.dispose();
    _mqttPrimaryUserCtrl.dispose();
    _mqttPrimaryPassCtrl.dispose();
    _mqttEmergencyHostCtrl.dispose();
    _mqttEmergencyPortCtrl.dispose();
    _mqttEmergencyUserCtrl.dispose();
    _mqttEmergencyPassCtrl.dispose();
    _siteIdCtrl.dispose();
    _plantNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _testApi() async {
    final url = _apiUrlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _apiTestState = TestState.failed;
        _apiTestMessage = 'Alamat Backend API tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _apiTestState = TestState.testing;
      _apiTestMessage = null;
    });

    final success = await ApiService.testApiConnection(url);

    if (mounted) {
      setState(() {
        if (success) {
          _apiTestState = TestState.success;
          _apiTestMessage = 'HTTP 200 OK — Backend API Berhasil Terhubung';
        } else {
          _apiTestState = TestState.failed;
          _apiTestMessage =
              'Koneksi Gagal — Server /health tidak memberikan respons valid';
        }
      });
    }
  }

  Future<void> _testMqtt() async {
    final host = _mqttPrimaryHostCtrl.text.trim();
    final port = int.tryParse(_mqttPrimaryPortCtrl.text.trim()) ?? 1883;
    final username = _mqttPrimaryUserCtrl.text.trim();
    final password = _mqttPrimaryPassCtrl.text;

    if (host.isEmpty) {
      setState(() {
        _mqttTestState = TestState.failed;
        _mqttTestMessage = 'Host Primary MQTT Broker tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _mqttTestState = TestState.testing;
      _mqttTestMessage = null;
    });

    final success = await MqttService.testMqttConnection(
      host: host,
      port: port,
      username: username,
      password: password,
    );

    if (mounted) {
      setState(() {
        if (success) {
          _mqttTestState = TestState.success;
          _mqttTestMessage = 'MQTT Terhubung — Broker Utama Siap';
        } else {
          _mqttTestState = TestState.failed;
          _mqttTestMessage =
              'Koneksi MQTT Gagal — Tidak dapat terhubung ke $host:$port';
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formattedApiUrl = RuntimeConfig.formatApiUrl(_apiUrlCtrl.text.trim());

    final newConfig = RuntimeConfig(
      apiBaseUrl: formattedApiUrl,
      mqttPrimaryHost: _mqttPrimaryHostCtrl.text.trim(),
      mqttPrimaryPort:
          int.tryParse(_mqttPrimaryPortCtrl.text.trim()) ?? 1883,
      mqttPrimaryUsername: _mqttPrimaryUserCtrl.text.trim(),
      mqttPrimaryPassword: _mqttPrimaryPassCtrl.text,
      mqttEmergencyHost: _mqttEmergencyHostCtrl.text.trim(),
      mqttEmergencyPort:
          int.tryParse(_mqttEmergencyPortCtrl.text.trim()) ?? 1883,
      mqttEmergencyUsername: _mqttEmergencyUserCtrl.text.trim(),
      mqttEmergencyPassword: _mqttEmergencyPassCtrl.text,
      siteId: _siteIdCtrl.text.trim(),
      plantName: _plantNameCtrl.text.trim(),
      isConfigured: true,
    );

    await ref
        .read(runtimeConfigProvider.notifier)
        .updateConfig(newConfig);

    ref.read(mqttProvider.notifier).reconnectWithNewConfig();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan koneksi berhasil diperbarui & disimpan.'),
          backgroundColor: AppTheme.statusOptimal,
        ),
      );
      if (widget.isEditing) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1210),
      appBar: widget.isEditing
          ? AppBar(
              backgroundColor: const Color(0xFF2A1F1A),
              title: const Text('Pengaturan Koneksi Plant'),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.isEditing) ...[
                  const SizedBox(height: 12),
                  // Header Branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/icons/app_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'NICEGAS / BioCNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'by CoreSight',
                          style: TextStyle(
                            color: AppTheme.primary.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Title Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1F1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.settings_input_component_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isEditing
                                  ? 'Konfigurasi Endpoint Connection'
                                  : 'Plant Connection Setup',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atur alamat Backend API dan Broker MQTT untuk jaringan kilang plant real-time.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 1: Backend API
                _buildSectionHeader('1. Backend REST API'),
                const SizedBox(height: 10),
                _DarkTextField(
                  controller: _apiUrlCtrl,
                  label: 'Backend API Endpoint',
                  hint: 'http://192.168.x.x:8000',
                  icon: Icons.api_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'URL API wajib diisi' : null,
                ),
                const SizedBox(height: 10),

                // API Test Status & Button
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _apiTestState == TestState.testing
                          ? null
                          : _testApi,
                      icon: _apiTestState == TestState.testing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(Icons.speed_rounded, size: 16),
                      label: const Text('Test API'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTestResultBadge(
                          _apiTestState, _apiTestMessage),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION 2: Primary MQTT Broker
                _buildSectionHeader('2. Primary MQTT Broker'),
                const SizedBox(height: 10),
                _DarkTextField(
                  controller: _mqttPrimaryHostCtrl,
                  label: 'Primary Broker Host',
                  hint: '192.168.x.x',
                  icon: Icons.router_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Host Primary Broker wajib diisi'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DarkTextField(
                        controller: _mqttPrimaryPortCtrl,
                        label: 'Port',
                        hint: '1883',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _DarkTextField(
                        controller: _mqttPrimaryUserCtrl,
                        label: 'Username (Opsional)',
                        hint: 'nicegas_usr',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DarkTextField(
                  controller: _mqttPrimaryPassCtrl,
                  label: 'Password (Opsional)',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                // MQTT Test Status & Button
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _mqttTestState == TestState.testing
                          ? null
                          : _testMqtt,
                      icon: _mqttTestState == TestState.testing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(Icons.sensors_rounded, size: 16),
                      label: const Text('Test MQTT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTestResultBadge(
                          _mqttTestState, _mqttTestMessage),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION 3: Emergency Broker (Optional)
                _buildSectionHeader('3. Emergency MQTT Broker (Opsional)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _DarkTextField(
                        controller: _mqttEmergencyHostCtrl,
                        label: 'Emergency Broker Host',
                        hint: '192.168.x.y (Opsional)',
                        icon: Icons.shield_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _DarkTextField(
                        controller: _mqttEmergencyPortCtrl,
                        label: 'Port',
                        hint: '1883',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DarkTextField(
                        controller: _mqttEmergencyUserCtrl,
                        label: 'Username Emergency (Opsional)',
                        hint: 'emg_usr',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DarkTextField(
                        controller: _mqttEmergencyPassCtrl,
                        label: 'Password Emergency (Opsional)',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION 4: Plant / Site Scope
                _buildSectionHeader('4. Plant / Site Scope'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DarkTextField(
                        controller: _siteIdCtrl,
                        label: 'Site / Plant ID',
                        hint: 'plant-alpha',
                        icon: Icons.factory_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _DarkTextField(
                        controller: _plantNameCtrl,
                        label: 'Nama Plant',
                        hint: 'Bio-CNG Plant Alpha',
                        icon: Icons.label_outline_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save & Continue Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEditing
                              ? 'Simpan & Terapkan'
                              : 'Save & Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primary.withValues(alpha: 0.9),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTestResultBadge(TestState state, String? message) {
    if (state == TestState.idle) {
      return Text(
        'Belum diuji',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
      );
    }
    if (state == TestState.testing) {
      return const Text(
        'Menguji koneksi...',
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final isSuccess = state == TestState.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isSuccess ? AppTheme.statusOptimal : AppTheme.statusCritical)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isSuccess ? AppTheme.statusOptimal : AppTheme.statusCritical)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 14,
            color: isSuccess ? AppTheme.statusOptimal : AppTheme.statusCritical,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message ?? (isSuccess ? 'Terhubung' : 'Gagal'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSuccess ? AppTheme.statusOptimal : AppTheme.statusCritical,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.statusCritical),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
