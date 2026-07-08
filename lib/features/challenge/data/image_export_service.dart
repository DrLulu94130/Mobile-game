import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../editor/domain/entities/placed_inkling.dart';
import '../../editor/domain/photo_framing.dart';
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

  /// Renders [inklings] over [photo] in the fixed story-style vertical
  /// canvas, stamps the Inkognito branding, and returns JPEG bytes.
  Future<Uint8List> render({
    required ui.Image photo,
    required List<PlacedInkling> inklings,
    required bool revealed,
    bool hd = false,
    double photoScale = 1.0,
    Offset photoPan = Offset.zero,
  }) async {
    final maxEdge = hd ? _hdEdge : _standardEdge;
    final outH = maxEdge;
    final outW = (maxEdge * PhotoFraming.canvasAspect).round();
    final canvasSize = Size(outW.toDouble(), outH.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.clipRect(Offset.zero & canvasSize);

    // 1. Draw the photo with the exact framing chosen in the editor.
    final dest = PhotoFraming.destRect(
      canvasSize,
      photo.width / photo.height,
      photoScale,
      photoPan,
    );
    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );

    // 2. Draw each Inkling with its camouflage painting.
    for (final inkling in inklings) {
      _paintInkling(canvas, canvasSize, inkling);
      if (revealed) _paintRevealRing(canvas, canvasSize, inkling);
    }

    // 3. Brand the image for sharing.
    _paintWatermark(canvas, canvasSize);

    final picture = recorder.endRecording();
    final image = await picture.toImage(outW, outH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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

  /// Stamps "INKOGNITO — Can you find the hidden creature?" over a soft
  /// bottom scrim so shared stories carry the game's signature.
  void _paintWatermark(Canvas canvas, Size size) {
    final scrimHeight = size.height * 0.16;
    final scrimRect = Rect.fromLTWH(
      0,
      size.height - scrimHeight,
      size.width,
      scrimHeight,
    );
    canvas.drawRect(
      scrimRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.55),
          ],
        ).createShader(scrimRect),
    );

    final pad = size.width * 0.05;
    final title = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'INKOGNITO',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.055,
          fontWeight: FontWeight.w900,
          letterSpacing: size.width * 0.004,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
        ),
      ),
    )..layout();
    final tagline = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'Can you find the hidden creature?',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: size.width * 0.034,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
        ),
      ),
    )..layout(maxWidth: size.width - pad * 2);

    final baseY = size.height - pad - tagline.height - title.height - 4;
    title.paint(canvas, Offset(pad, baseY));
    tagline.paint(canvas, Offset(pad, baseY + title.height + 4));
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
