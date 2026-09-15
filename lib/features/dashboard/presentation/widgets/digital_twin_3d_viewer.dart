import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/digital_twin_targets.dart';

class DigitalTwin3dViewer extends StatefulWidget {
  final double height;
  final DigitalTwinNode selectedNode;
  final ValueChanged<DigitalTwinNode>? onNodeSelected;

  const DigitalTwin3dViewer({
    super.key,
    this.height = 280,
    this.selectedNode = DigitalTwinNode.overview,
    this.onNodeSelected,
  });

  @override
  State<DigitalTwin3dViewer> createState() => _DigitalTwin3dViewerState();
}

class _DigitalTwin3dViewerState extends State<DigitalTwin3dViewer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Safety fallback to dismiss loading screen once webview renders
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final targetConfig = DigitalTwinTargets.getTarget(widget.selectedNode);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 3D Model Viewer with dynamic Camera Target and Orbit
          if (!_hasError)
            ModelViewer(
              key: const ValueKey('bio_cng_plant_model_viewer'),
              src: 'assets/3D_Digital_Twin/BioCNG_Plant.glb',
              alt: 'BioCNG Plant 3D Digital Twin Model',
              ar: false,
              autoRotate: false,
              cameraControls: true,
              touchAction: TouchAction.panY,
              backgroundColor: Colors.transparent,
              cameraTarget: targetConfig.cameraTarget,
              cameraOrbit: targetConfig.cameraOrbit,
              fieldOfView: targetConfig.fieldOfView,
              loading: Loading.eager,
            ),

          // Error Fallback State
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.statusCritical,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gagal memuat model 3D',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                      });
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),

          // Loading Overlay
          if (_isLoading && !_hasError)
            Container(
              color: AppTheme.background,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Memuat Miniature Digital Twin 3D...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top Bar Overlay: Active Focus Indicator & Reset/Overview Button
          if (!_isLoading && !_hasError)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active Node Focus Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.selectedNode == DigitalTwinNode.overview
                              ? Icons.center_focus_strong_rounded
                              : Icons.my_location_rounded,
                          color: widget.selectedNode == DigitalTwinNode.overview
                              ? Colors.white70
                              : AppTheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.selectedNode == DigitalTwinNode.overview
                              ? 'Full Plant View'
                              : 'Focus: ${targetConfig.label}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reset Camera to Overview Button
                  if (widget.selectedNode != DigitalTwinNode.overview)
                    GestureDetector(
                      key: const Key('reset_overview_button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.onNodeSelected?.call(DigitalTwinNode.overview);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restart_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Reset Overview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Bottom Overlay: Interaction Gesture Hint
          if (!_isLoading && !_hasError)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.threed_rotation_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Rotate / Zoom / Pan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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
