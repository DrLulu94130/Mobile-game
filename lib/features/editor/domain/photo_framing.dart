import 'dart:ui';

/// Shared math for framing the photo inside the fixed vertical canvas.
///
/// The photo always cover-fills the canvas; the player can additionally zoom
/// ([scale] >= 1) and pan it. The exact same helpers drive the editor preview
/// and the final export so the published image matches what was on screen.
abstract class PhotoFraming {
  /// The story-style canvas every challenge uses.
  static const double canvasAspect = 9 / 16;

  static const double minScale = 1.0;
  static const double maxScale = 4.0;

  /// Where the photo lands in canvas pixels for the given framing.
  static Rect destRect(
    Size canvas,
    double photoAspect,
    double scale,
    Offset pan,
  ) {
    final canvasAspectHere = canvas.width / canvas.height;
    double w, h;
    if (photoAspect > canvasAspectHere) {
      h = canvas.height * scale;
      w = h * photoAspect;
    } else {
      w = canvas.width * scale;
      h = w / photoAspect;
    }
    final left = (canvas.width - w) / 2 + pan.dx * canvas.width;
    final top = (canvas.height - h) / 2 + pan.dy * canvas.height;
    return Rect.fromLTWH(left, top, w, h);
  }

  /// Clamps [pan] (in canvas-fraction units) so the photo always covers the
  /// whole canvas — no empty edges, ever.
  static Offset clampPan(
    Size canvas,
    double photoAspect,
    double scale,
    Offset pan,
  ) {
    final rect = destRect(canvas, photoAspect, scale, Offset.zero);
    final maxDx = ((rect.width - canvas.width) / 2) / canvas.width;
    final maxDy = ((rect.height - canvas.height) / 2) / canvas.height;
    return Offset(
      pan.dx.clamp(-maxDx, maxDx),
      pan.dy.clamp(-maxDy, maxDy),
    );
  }

  /// Maps a normalised canvas point (0..1) to a normalised photo point
  /// (0..1), for colour sampling. Returns values clamped into the photo.
  static Offset canvasNormToPhotoNorm(
    Offset canvasNorm,
    Size canvas,
    double photoAspect,
    double scale,
    Offset pan,
  ) {
    final dest = destRect(canvas, photoAspect, scale, pan);
    final px = Offset(canvasNorm.dx * canvas.width, canvasNorm.dy * canvas.height);
    return Offset(
      ((px.dx - dest.left) / dest.width).clamp(0.0, 1.0),
      ((px.dy - dest.top) / dest.height).clamp(0.0, 1.0),
    );
  }
}
