import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/mascot_models.dart';
import '../../domain/sprite_registry.dart';

const _uuid = Uuid();

/// The posing booth: spin the white chameleon to pick its pose, then capture
/// it as a transparent sprite ready to hide on the photo.
///
/// Pops with the registered sprite id, or null when dismissed.
class PoseBoothScreen extends StatefulWidget {
  const PoseBoothScreen({super.key});

  @override
  State<PoseBoothScreen> createState() => _PoseBoothScreenState();
}

class _PoseBoothScreenState extends State<PoseBoothScreen> {
  WebViewController? _web;
  bool _capturing = false;
  int _poseIndex = 0;

  Future<void> _capture() async {
    final web = _web;
    if (web == null || _capturing) return;
    setState(() => _capturing = true);
    // The channel callback finishes the flow; see _onSpriteCaptured.
    await web.runJavaScript('''
      (function () {
        var mv = document.querySelector('model-viewer');
        if (!mv) { SpriteChannel.postMessage('error:no-viewer'); return; }
        try {
          SpriteChannel.postMessage(mv.toDataURL('image/png'));
        } catch (e) {
          SpriteChannel.postMessage('error:' + e);
        }
      })();
    ''');
  }

  Future<void> _onSpriteCaptured(String dataUrl) async {
    if (!dataUrl.startsWith('data:image/png;base64,')) {
      if (mounted) {
        setState(() => _capturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capture failed — try again')),
        );
      }
      return;
    }
    final bytes = base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    final id = _uuid.v4();
    SpriteRegistry.instance.register(id, frame.image, bytes);
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const Text(
                'Strike a pose!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drag to spin — this is how you will hide.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Center(
                  // Square viewport so the captured sprite is square too.
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ModelViewer(
                      key: ValueKey(kMascotPoses[_poseIndex].asset),
                      src: kMascotPoses[_poseIndex].asset,
                      alt: 'Pose the character',
                      backgroundColor: Colors.transparent,
                      cameraControls: true,
                      disableZoom: false,
                      disablePan: true,
                      autoRotate: false,
                      interactionPrompt: InteractionPrompt.none,
                      cameraOrbit: '25deg 78deg 105%',
                      fieldOfView: '28deg',
                      onWebViewCreated: (controller) {
                        _web = controller;
                        controller.addJavaScriptChannel(
                          'SpriteChannel',
                          onMessageReceived: (msg) =>
                              _onSpriteCaptured(msg.message),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Pose selector — appears as soon as more .glb poses are added
              // to kMascotPoses.
              if (kMascotPoses.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: kMascotPoses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ChoiceChip(
                      label: Text(kMascotPoses[i].label),
                      selected: i == _poseIndex,
                      onSelected: (_) => setState(() => _poseIndex = i),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _capturing ? null : _capture,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.glow,
                      foregroundColor: const Color(0xFF3D2E00),
                      minimumSize: const Size.fromHeight(58),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    icon: _capturing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.pets),
                    label: Text(_capturing ? 'Capturing…' : 'Hide me!'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
