import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/placed_inkling.dart';
import '../../domain/photo_framing.dart';
import '../painters/inkling_painter.dart';
import '../state/editor_controller.dart';
import '../state/editor_state.dart';

/// Callback used by the eyedropper: reports a tapped point in normalised
/// canvas coordinates so the host can sample the photo colour there.
typedef ColorSampler = void Function(Offset normalisedCanvasPoint);

/// The interactive editor surface: the photo, the placed Inklings and all
/// gesture handling for moving, transforming and drawing.
class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    required this.photo,
    required this.photoAspect,
    required this.state,
    required this.controller,
    required this.onSampleColor,
    super.key,
  });

  final ImageProvider photo;

  /// Width / height of the source photo, used to cover-fit it inside the
  /// fixed vertical canvas.
  final double photoAspect;

  final EditorState state;
  final EditorController controller;
  final ColorSampler onSampleColor;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  // Baselines captured at the start of a transform gesture.
  Offset? _baseCenter;
  double? _baseSize;
  double? _baseRotation;
  Offset? _gestureStartFocal;

  // When the move gesture starts on empty space, it reframes the photo.
  bool _framingPhoto = false;
  double? _basePhotoScale;
  Offset? _basePhotoPan;

  Size _canvas = Size.zero;
  final TransformationController _viewer = TransformationController();

  @override
  void dispose() {
    _viewer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvas = Size(constraints.maxWidth, constraints.maxHeight);
        final tool = widget.state.tool;
        final zoom = widget.state.zoomEnabled;

        final photoRect = PhotoFraming.destRect(
          _canvas,
          widget.photoAspect,
          widget.state.photoScale,
          widget.state.photoPan,
        );
        Widget stack = Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fromRect(
              rect: photoRect,
              child: Image(image: widget.photo, fit: BoxFit.fill),
            ),
            ...widget.state.inklings.map(_buildInkling),
          ],
        );

        // In zoom mode the InteractiveViewer owns all gestures; otherwise the
        // tool-specific handler does. The zoom transform persists after
        // leaving zoom mode, so users can pan in, then draw with precision —
        // gesture coordinates are mapped back into child space automatically.
        if (!zoom) {
          switch (tool) {
            case EditorTool.move:
              stack = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _selectAt,
                onScaleStart: _onTransformStart,
                onScaleUpdate: _onTransformUpdate,
                onScaleEnd: (_) => widget.controller.endTransform(),
                child: stack,
              );
            case EditorTool.brush:
            case EditorTool.eraser:
              stack = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onDrawStart,
                onPanUpdate: _onDrawUpdate,
                onPanEnd: (_) => widget.controller.endStroke(),
                child: stack,
              );
            case EditorTool.eyedropper:
              stack = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) =>
                    widget.onSampleColor(_normalise(d.localPosition)),
                child: stack,
              );
          }
        }

        return ClipRect(
          child: InteractiveViewer(
            transformationController: _viewer,
            panEnabled: zoom,
            scaleEnabled: zoom,
            minScale: 1,
            maxScale: 5,
            child: stack,
          ),
        );
      },
    );
  }

  Widget _buildInkling(PlacedInkling inkling) {
    final rect = inkling.rectFor(_canvas);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: inkling.rotation,
        child: CustomPaint(
          painter: InklingPainter(
            inkling: inkling,
            selected: inkling.id == widget.state.selectedId,
          ),
        ),
      ),
    );
  }

  // --- Selection & transform (move tool) ---

  void _selectAt(TapUpDetails details) {
    final id = _inklingAt(details.localPosition);
    widget.controller.select(id);
  }

  void _onTransformStart(ScaleStartDetails details) {
    _framingPhoto = false;
    // Select what is under the initial focal point if nothing is selected.
    final id = _inklingAt(details.localFocalPoint);
    if (id != null && id != widget.state.selectedId) {
      widget.controller.select(id);
    }
    final sel = id == null ? null : widget.controller.snapshot.selected;
    _gestureStartFocal = details.localFocalPoint;
    if (sel == null) {
      // Empty space: the gesture reframes the photo instead.
      widget.controller.select(null);
      _framingPhoto = true;
      _basePhotoScale = widget.state.photoScale;
      _basePhotoPan = widget.state.photoPan;
      return;
    }
    _baseCenter = sel.center;
    _baseSize = sel.size;
    _baseRotation = sel.rotation;
  }

  void _onTransformUpdate(ScaleUpdateDetails details) {
    if (_gestureStartFocal == null) return;
    final deltaPx = details.localFocalPoint - _gestureStartFocal!;

    if (_framingPhoto) {
      final scale = (_basePhotoScale! * details.scale).clamp(
        PhotoFraming.minScale,
        PhotoFraming.maxScale,
      );
      final pan = PhotoFraming.clampPan(
        _canvas,
        widget.photoAspect,
        scale,
        _basePhotoPan! +
            Offset(deltaPx.dx / _canvas.width, deltaPx.dy / _canvas.height),
      );
      widget.controller.setPhotoTransform(scale: scale, pan: pan);
      return;
    }

    if (_baseCenter == null) return;
    final newCenter = Offset(
      _baseCenter!.dx + deltaPx.dx / _canvas.width,
      _baseCenter!.dy + deltaPx.dy / _canvas.height,
    );
    widget.controller.transformSelected(
      center: newCenter,
      size: _baseSize! * details.scale,
      rotation: _baseRotation! + details.rotation,
    );
  }

  // --- Drawing (brush / eraser tools) ---

  void _onDrawStart(DragStartDetails details) {
    final local = _toInklingLocal(details.localPosition);
    if (local == null) return;
    widget.controller.beginStroke(local);
  }

  void _onDrawUpdate(DragUpdateDetails details) {
    final local = _toInklingLocal(details.localPosition);
    if (local == null) return;
    widget.controller.extendStroke(local);
  }

  // --- Coordinate helpers ---

  Offset _normalise(Offset px) =>
      Offset(px.dx / _canvas.width, px.dy / _canvas.height);

  /// Returns the id of the top-most Inkling under [px], or null.
  String? _inklingAt(Offset px) {
    for (final inkling in widget.state.inklings.reversed) {
      if (_localWithin(inkling, px) != null) return inkling.id;
    }
    return null;
  }

  /// Maps a screen point into the *selected* Inkling's local [0,1] space,
  /// returning null if the point falls outside the creature.
  Offset? _toInklingLocal(Offset px) {
    final sel = widget.state.selected;
    if (sel == null) return null;
    return _localWithin(sel, px);
  }

  /// Local-space mapping shared by hit-testing and drawing.
  Offset? _localWithin(PlacedInkling inkling, Offset px) {
    final rect = inkling.rectFor(_canvas);
    final center = rect.center;
    final v = px - center;
    // Undo the Inkling's rotation.
    final s = math.sin(-inkling.rotation);
    final c = math.cos(-inkling.rotation);
    final rx = v.dx * c - v.dy * s;
    final ry = v.dx * s + v.dy * c;
    final local = Offset(rx / rect.width + 0.5, ry / rect.height + 0.5);
    if (local.dx < 0 || local.dx > 1 || local.dy < 0 || local.dy > 1) {
      return null;
    }
    return local;
  }
}
