/// Application-wide configuration managed via --dart-define.
class AppConfig {
  /// Base URL for the REST API.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.nicegas.com/v1',
  );

  /// MQTT Primary Broker Host.
  static const String mqttPrimaryHost = String.fromEnvironment(
    'MQTT_PRIMARY_HOST',
    defaultValue: String.fromEnvironment('MQTT_HOST', defaultValue: ''),
  );

  /// MQTT Primary Broker Port.
  static const int mqttPrimaryPort = int.fromEnvironment(
    'MQTT_PRIMARY_PORT',
    defaultValue: int.fromEnvironment('MQTT_PORT', defaultValue: 1883),
  );

  /// MQTT Primary Broker Username.
  static const String mqttPrimaryUsername = String.fromEnvironment(
    'MQTT_PRIMARY_USERNAME',
    defaultValue: String.fromEnvironment('MQTT_USERNAME', defaultValue: ''),
  );

  /// MQTT Primary Broker Password.
  static const String mqttPrimaryPassword = String.fromEnvironment(
    'MQTT_PRIMARY_PASSWORD',
    defaultValue: String.fromEnvironment('MQTT_PASSWORD', defaultValue: ''),
  );

  /// MQTT Emergency Broker Host.
  static const String mqttEmergencyHost = String.fromEnvironment(
    'MQTT_EMERGENCY_HOST',
    defaultValue: '',
  );

  /// MQTT Emergency Broker Port.
  static const int mqttEmergencyPort = int.fromEnvironment(
    'MQTT_EMERGENCY_PORT',
    defaultValue: 1883,
  );

  /// MQTT Emergency Broker Username.
  static const String mqttEmergencyUsername = String.fromEnvironment(
    'MQTT_EMERGENCY_USERNAME',
    defaultValue: '',
  );

  /// MQTT Emergency Broker Password.
  static const String mqttEmergencyPassword = String.fromEnvironment(
    'MQTT_EMERGENCY_PASSWORD',
    defaultValue: '',
  );

  /// MQTT Client ID.
  static const String mqttClientId = String.fromEnvironment(
    'MQTT_CLIENT_ID',
    defaultValue: 'nicegas_flutter_client',
  );

  /// MQTT Keepalive (seconds).
  static const int mqttKeepalive = int.fromEnvironment(
    'MQTT_KEEPALIVE',
    defaultValue: 60,
  );

  /// Current Environment Name.
  static const String envName = String.fromEnvironment(
    'ENV_NAME',
    defaultValue: 'development',
  );

  /// Whether the app is running in Demo Mode.
  static const bool isDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  /// Prevents instantiation.
  AppConfig._();
}
