import 'dart:typed_data';
import 'dart:ui' as ui;

/// In-memory store of captured chameleon body sprites.
///
/// The pose booth captures the posed 3D model as a transparent PNG and
/// registers it here under a fresh sprite id; the editor canvas and the image
/// export service resolve the same id when painting. Published challenges are
/// flattened to plain images, so sprites only need to live for the editing
/// session.
class SpriteRegistry {
  SpriteRegistry._();

  static final SpriteRegistry instance = SpriteRegistry._();

  final Map<String, ui.Image> _images = {};
  final Map<String, Uint8List> _bytes = {};

  void register(String id, ui.Image image, Uint8List pngBytes) {
    _images[id]?.dispose();
    _images[id] = image;
    _bytes[id] = pngBytes;
  }

  ui.Image? imageOf(String? id) => id == null ? null : _images[id];

  Uint8List? bytesOf(String? id) => id == null ? null : _bytes[id];
}
