import 'app_config.dart';

/// Represents operator-configured connection settings at runtime.
/// Fallbacks to [AppConfig] compile-time defaults if unconfigured or empty.
class RuntimeConfig {
  final String apiBaseUrl;
  final String mqttPrimaryHost;
  final int mqttPrimaryPort;
  final String mqttPrimaryUsername;
  final String mqttPrimaryPassword;
  final String mqttEmergencyHost;
  final int mqttEmergencyPort;
  final String mqttEmergencyUsername;
  final String mqttEmergencyPassword;
  final String siteId;
  final String plantName;
  final bool isConfigured;

  const RuntimeConfig({
    this.apiBaseUrl = '',
    this.mqttPrimaryHost = '',
    this.mqttPrimaryPort = 1883,
    this.mqttPrimaryUsername = '',
    this.mqttPrimaryPassword = '',
    this.mqttEmergencyHost = '',
    this.mqttEmergencyPort = 1883,
    this.mqttEmergencyUsername = '',
    this.mqttEmergencyPassword = '',
    this.siteId = '',
    this.plantName = '',
    this.isConfigured = false,
  });

  static String formatApiUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url;
  }

  String get effectiveApiBaseUrl {
    final formatted = formatApiUrl(apiBaseUrl);
    return formatted.isNotEmpty ? formatted : formatApiUrl(AppConfig.apiBaseUrl);
  }

  String get effectiveMqttPrimaryHost => mqttPrimaryHost.trim().isNotEmpty
      ? mqttPrimaryHost.trim()
      : AppConfig.mqttPrimaryHost;

  int get effectiveMqttPrimaryPort =>
      mqttPrimaryPort > 0 ? mqttPrimaryPort : AppConfig.mqttPrimaryPort;

  String get effectiveMqttPrimaryUsername =>
      mqttPrimaryUsername.isNotEmpty ? mqttPrimaryUsername : AppConfig.mqttPrimaryUsername;

  String get effectiveMqttPrimaryPassword =>
      mqttPrimaryPassword.isNotEmpty ? mqttPrimaryPassword : AppConfig.mqttPrimaryPassword;

  String get effectiveMqttEmergencyHost => mqttEmergencyHost.trim().isNotEmpty
      ? mqttEmergencyHost.trim()
      : AppConfig.mqttEmergencyHost;

  int get effectiveMqttEmergencyPort =>
      mqttEmergencyPort > 0 ? mqttEmergencyPort : AppConfig.mqttEmergencyPort;

  String get effectiveMqttEmergencyUsername =>
      mqttEmergencyUsername.isNotEmpty ? mqttEmergencyUsername : AppConfig.mqttEmergencyUsername;

  String get effectiveMqttEmergencyPassword =>
      mqttEmergencyPassword.isNotEmpty ? mqttEmergencyPassword : AppConfig.mqttEmergencyPassword;

  String get effectiveSiteId =>
      siteId.trim().isNotEmpty ? siteId.trim() : 'plant-alpha';

  String get effectivePlantName =>
      plantName.trim().isNotEmpty ? plantName.trim() : 'Bio-CNG Plant Alpha';

  Map<String, dynamic> toJson() => {
        'apiBaseUrl': apiBaseUrl,
        'mqttPrimaryHost': mqttPrimaryHost,
        'mqttPrimaryPort': mqttPrimaryPort,
        'mqttPrimaryUsername': mqttPrimaryUsername,
        'mqttPrimaryPassword': mqttPrimaryPassword,
        'mqttEmergencyHost': mqttEmergencyHost,
        'mqttEmergencyPort': mqttEmergencyPort,
        'mqttEmergencyUsername': mqttEmergencyUsername,
        'mqttEmergencyPassword': mqttEmergencyPassword,
        'siteId': siteId,
        'plantName': plantName,
        'isConfigured': isConfigured,
      };

  factory RuntimeConfig.fromJson(Map<String, dynamic> json) => RuntimeConfig(
        apiBaseUrl: json['apiBaseUrl']?.toString() ?? '',
        mqttPrimaryHost: json['mqttPrimaryHost']?.toString() ?? '',
        mqttPrimaryPort: (json['mqttPrimaryPort'] as num?)?.toInt() ?? 1883,
        mqttPrimaryUsername: json['mqttPrimaryUsername']?.toString() ?? '',
        mqttPrimaryPassword: json['mqttPrimaryPassword']?.toString() ?? '',
        mqttEmergencyHost: json['mqttEmergencyHost']?.toString() ?? '',
        mqttEmergencyPort: (json['mqttEmergencyPort'] as num?)?.toInt() ?? 1883,
        mqttEmergencyUsername: json['mqttEmergencyUsername']?.toString() ?? '',
        mqttEmergencyPassword: json['mqttEmergencyPassword']?.toString() ?? '',
        siteId: json['siteId']?.toString() ?? '',
        plantName: json['plantName']?.toString() ?? '',
        isConfigured: json['isConfigured'] == true,
      );

  RuntimeConfig copyWith({
    String? apiBaseUrl,
    String? mqttPrimaryHost,
    int? mqttPrimaryPort,
    String? mqttPrimaryUsername,
    String? mqttPrimaryPassword,
    String? mqttEmergencyHost,
    int? mqttEmergencyPort,
    String? mqttEmergencyUsername,
    String? mqttEmergencyPassword,
    String? siteId,
    String? plantName,
    bool? isConfigured,
  }) =>
      RuntimeConfig(
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
        mqttPrimaryHost: mqttPrimaryHost ?? this.mqttPrimaryHost,
        mqttPrimaryPort: mqttPrimaryPort ?? this.mqttPrimaryPort,
        mqttPrimaryUsername: mqttPrimaryUsername ?? this.mqttPrimaryUsername,
        mqttPrimaryPassword: mqttPrimaryPassword ?? this.mqttPrimaryPassword,
        mqttEmergencyHost: mqttEmergencyHost ?? this.mqttEmergencyHost,
        mqttEmergencyPort: mqttEmergencyPort ?? this.mqttEmergencyPort,
        mqttEmergencyUsername: mqttEmergencyUsername ?? this.mqttEmergencyUsername,
        mqttEmergencyPassword: mqttEmergencyPassword ?? this.mqttEmergencyPassword,
        siteId: siteId ?? this.siteId,
        plantName: plantName ?? this.plantName,
        isConfigured: isConfigured ?? this.isConfigured,
      );
}
