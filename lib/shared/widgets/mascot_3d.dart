import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// A live, gently auto-rotating 3D render of the Inkognito mascot.
///
/// Renders the packaged `chameleon.glb` inside a transparent viewer so it can
/// sit on top of any gradient or scene. Users can drag to spin it.
class Mascot3D extends StatelessWidget {
  const Mascot3D({super.key, this.interactive = true});

  /// When false the model still auto-rotates but ignores touch.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: 'assets/models/chameleon.glb',
      alt: 'Inkognito mascot',
      backgroundColor: Colors.transparent,
      autoRotate: true,
      rotationPerSecond: '24deg',
      cameraControls: interactive,
      disableZoom: true,
      disablePan: true,
      // Pull the camera back and narrow the lens so the whole character is
      // framed like a product shot instead of an extreme close-up.
      cameraOrbit: '20deg 80deg 110%',
      cameraTarget: 'auto auto auto',
      fieldOfView: '26deg',
      minCameraOrbit: 'auto 65deg auto',
      maxCameraOrbit: 'auto 100deg auto',
    );
  }
}
