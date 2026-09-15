import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:itenice_bio_cng/features/dashboard/presentation/widgets/digital_twin_3d_viewer.dart';
import 'package:itenice_bio_cng/features/dashboard/presentation/models/digital_twin_targets.dart';

class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
}

class FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return FakeNavigationDelegate(params);
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return FakeWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakeWebViewWidget(params);
  }
}

class FakeWebViewController extends PlatformWebViewController {
  FakeWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) async {}
  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
}

class FakeWebViewWidget extends PlatformWebViewWidget {
  FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  testWidgets('DigitalTwin3dViewer renders loading and container initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DigitalTwin3dViewer(),
        ),
      ),
    );

    expect(find.text('Memuat Miniature Digital Twin 3D...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Memuat Miniature Digital Twin 3D...'), findsNothing);
    expect(find.text('Rotate / Zoom / Pan'), findsOneWidget);
    expect(find.text('Full Plant View'), findsOneWidget);
  });

  testWidgets('DigitalTwin3dViewer shows focus badge and reset button when node is selected', (WidgetTester tester) async {
    DigitalTwinNode? selectedNode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DigitalTwin3dViewer(
            selectedNode: DigitalTwinNode.biodigester,
            onNodeSelected: (node) => selectedNode = node,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Focus: Biodigester Node'), findsOneWidget);
    expect(find.byKey(const Key('reset_overview_button')), findsOneWidget);

    final resetBtn = tester.widget<GestureDetector>(find.byKey(const Key('reset_overview_button')));
    resetBtn.onTap!();
    expect(selectedNode, DigitalTwinNode.overview);
  });
}
