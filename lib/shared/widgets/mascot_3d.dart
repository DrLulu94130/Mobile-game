import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../features/editor/domain/entities/inkling_species.dart';
import 'inkling_avatar.dart';

/// A live, gently auto-rotating 3D render of the Inkognito mascot.
///
/// The underlying [ModelViewer] is backed by a WebView, which is expensive to
/// spin up. To keep the menu painting instantly, a lightweight painted Inkling
/// is shown first and the 3D viewer is mounted a beat after the first frame,
/// then cross-faded in. Users can drag to spin the model once it appears.
class Mascot3D extends StatefulWidget {
  const Mascot3D({super.key, this.interactive = true});

  /// When false the model still auto-rotates but ignores touch.
  final bool interactive;

  @override
  State<Mascot3D> createState() => _Mascot3DState();
}

class _Mascot3DState extends State<Mascot3D> {
  bool _showViewer = false;

  @override
  void initState() {
    super.initState();
    // Defer the heavy WebView until the menu has painted its first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _showViewer = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _showViewer
          ? _MascotViewer(
              key: const ValueKey('viewer'),
              interactive: widget.interactive,
            )
          : const Center(
              key: ValueKey('placeholder'),
              child: InklingAvatar(species: InklingSpecies.classic, size: 180),
            ),
    );
  }
}

class _MascotViewer extends StatelessWidget {
  const _MascotViewer({required this.interactive, super.key});

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
