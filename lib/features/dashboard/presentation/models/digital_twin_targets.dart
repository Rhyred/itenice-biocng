/// Centralized Single Source of Truth for 3D Digital Twin Node Targets & Orbits
enum DigitalTwinNode {
  overview,
  biodigester,
  purifikasi,
  kompresi,
}

class DigitalTwinTargetConfig {
  final String label;
  final String cameraTarget;
  final String cameraOrbit;
  final String fieldOfView;

  const DigitalTwinTargetConfig({
    required this.label,
    required this.cameraTarget,
    required this.cameraOrbit,
    this.fieldOfView = '30deg',
  });
}

class DigitalTwinTargets {
  DigitalTwinTargets._();

  /// Miniature Plant Overview (Framing full plant)
  static const overview = DigitalTwinTargetConfig(
    label: 'Full Plant Overview',
    cameraTarget: '0m 0m 0m',
    cameraOrbit: '45deg 75deg 105%',
    fieldOfView: '30deg',
  );

  /// Biodigester Section (Left cluster)
  static const biodigester = DigitalTwinTargetConfig(
    label: 'Biodigester Node',
    cameraTarget: '-88m 3m 7m',
    cameraOrbit: '45deg 70deg 45m',
    fieldOfView: '30deg',
  );

  /// Purifikasi Section (Center scrubber towers)
  static const purifikasi = DigitalTwinTargetConfig(
    label: 'Purifikasi Node',
    cameraTarget: '-4m 4m 0m',
    cameraOrbit: '45deg 70deg 50m',
    fieldOfView: '30deg',
  );

  /// Kompresi Section (Right compressor skids & cascade)
  static const kompresi = DigitalTwinTargetConfig(
    label: 'Kompresi Node',
    cameraTarget: '58m -5m 3m',
    cameraOrbit: '45deg 70deg 45m',
    fieldOfView: '30deg',
  );

  static DigitalTwinTargetConfig getTarget(DigitalTwinNode node) {
    switch (node) {
      case DigitalTwinNode.overview:
        return overview;
      case DigitalTwinNode.biodigester:
        return biodigester;
      case DigitalTwinNode.purifikasi:
        return purifikasi;
      case DigitalTwinNode.kompresi:
        return kompresi;
    }
  }

  /// Maps integer tab index to [DigitalTwinNode]
  /// 0 -> Biodigester, 1 -> Purifikasi, 2 -> Kompresi, otherwise -> Overview
  static DigitalTwinNode fromIndex(int index) {
    switch (index) {
      case 0:
        return DigitalTwinNode.biodigester;
      case 1:
        return DigitalTwinNode.purifikasi;
      case 2:
        return DigitalTwinNode.kompresi;
      default:
        return DigitalTwinNode.overview;
    }
  }

  /// Maps [DigitalTwinNode] to integer tab index (-1 for Overview)
  static int toIndex(DigitalTwinNode node) {
    switch (node) {
      case DigitalTwinNode.biodigester:
        return 0;
      case DigitalTwinNode.purifikasi:
        return 1;
      case DigitalTwinNode.kompresi:
        return 2;
      case DigitalTwinNode.overview:
        return -1;
    }
  }
}
