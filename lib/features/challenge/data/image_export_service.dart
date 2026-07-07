import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../editor/domain/entities/placed_inkling.dart';
import '../../editor/presentation/painters/inkling_painter.dart';

/// Composites the source photo with the placed Inklings into shareable images.
///
/// Produces two outputs:
///  * **camouflaged** — the puzzle players receive.
///  * **revealed** — the solution with highlight rings around each Inkling.
class ImageExportService {
  const ImageExportService();

  /// Maximum exported edge length (px). HD export is unlocked for Premium.
  static const int _standardEdge = 1080;
  static const int _hdEdge = 2160;

  Future<ui.Image> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Renders [inklings] over [photo], returning JPEG bytes.
  Future<Uint8List> render({
    required ui.Image photo,
    required List<PlacedInkling> inklings,
    required bool revealed,
    bool hd = false,
  }) async {
    final maxEdge = hd ? _hdEdge : _standardEdge;
    final aspect = photo.width / photo.height;
    final (outW, outH) = aspect >= 1
        ? (maxEdge, (maxEdge / aspect).round())
        : ((maxEdge * aspect).round(), maxEdge);
    final canvasSize = Size(outW.toDouble(), outH.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Draw the photo scaled to fill the output.
    paintImage(
      canvas: canvas,
      rect: Offset.zero & canvasSize,
      image: photo,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );

    // 2. Draw each Inkling with its camouflage painting.
    for (final inkling in inklings) {
      _paintInkling(canvas, canvasSize, inkling);
      if (revealed) _paintRevealRing(canvas, canvasSize, inkling);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(outW, outH);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    picture.dispose();
    image.dispose();

    // 3. Encode to JPEG (smaller for network sharing) via the image package.
    final raw = byteData!.buffer.asUint8List();
    final decoded = img.Image.fromBytes(
      width: outW,
      height: outH,
      bytes: raw.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
  }

  void _paintInkling(Canvas canvas, Size canvasSize, PlacedInkling inkling) {
    final rect = inkling.rectFor(canvasSize);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(inkling.rotation);
    canvas.translate(-rect.width / 2, -rect.height / 2);
    InklingPainter(inkling: inkling)
        .paint(canvas, Size(rect.width, rect.height));
    canvas.restore();
  }

  void _paintRevealRing(Canvas canvas, Size canvasSize, PlacedInkling inkling) {
    final rect = inkling.rectFor(canvasSize);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.shortestSide * 0.06
      ..color = const Color(0xFF00CEC9);
    canvas.drawCircle(rect.center, rect.width * 0.62, ring);
  }
}

/// Loads a bundled asset (e.g. a sample photo) as decoded bytes.
Future<Uint8List> loadAssetBytes(String key) async {
  final data = await rootBundle.load(key);
  return data.buffer.asUint8List();
}

final imageExportServiceProvider = Provider<ImageExportService>(
  (ref) => const ImageExportService(),
);
