/// Application-wide configuration managed via --dart-define.
class AppConfig {
  /// Base URL for the REST API.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.nicegas.com/v1',
  );

  /// MQTT Broker Host.
  static const String mqttHost = String.fromEnvironment(
    'MQTT_HOST',
    defaultValue: '',
  );

  /// MQTT Broker Port.
  static const int mqttPort = int.fromEnvironment(
    'MQTT_PORT',
    defaultValue: 1883,
  );

  /// Current Environment Name.
  static const String envName = String.fromEnvironment(
    'ENV_NAME',
    defaultValue: 'development',
  );

  /// Prevents instantiation.
  AppConfig._();
}
