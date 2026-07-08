import 'package:flutter/material.dart';

import '../../domain/entities/placed_inkling.dart';

/// The active tool in the editor.
enum EditorTool {
  move, // select / drag / scale / rotate creatures
  brush, // paint camouflage inside the selected creature
  eraser,
  eyedropper, // sample a colour from the photo behind
}

/// Immutable snapshot of the editor canvas.
@immutable
class EditorState {
  const EditorState({
    required this.inklings,
    this.selectedId,
    this.tool = EditorTool.move,
    this.brushColor = const Color(0xFF6C5CE7),
    this.brushSize = 0.08,
    this.zoom = 1.0,
    this.zoomEnabled = false,
    this.canUndo = false,
    this.canRedo = false,
    this.isExporting = false,
    this.photoScale = 1.0,
    this.photoPan = Offset.zero,
  });

  final List<PlacedInkling> inklings;
  final String? selectedId;
  final EditorTool tool;
  final Color brushColor;

  /// Brush width as a fraction of the selected Inkling's local size.
  final double brushSize;

  final double zoom;

  /// When true, the canvas is in pan/pinch-to-zoom mode (editing gestures are
  /// suspended so the user can inspect fine detail).
  final bool zoomEnabled;

  final bool canUndo;
  final bool canRedo;
  final bool isExporting;

  /// Framing of the photo inside the fixed vertical canvas (zoom + pan).
  final double photoScale;
  final Offset photoPan;

  PlacedInkling? get selected {
    for (final i in inklings) {
      if (i.id == selectedId) return i;
    }
    return null;
  }

  bool get hasInklings => inklings.isNotEmpty;

  EditorState copyWith({
    List<PlacedInkling>? inklings,
    String? selectedId,
    bool clearSelection = false,
    EditorTool? tool,
    Color? brushColor,
    double? brushSize,
    double? zoom,
    bool? zoomEnabled,
    bool? canUndo,
    bool? canRedo,
    bool? isExporting,
    double? photoScale,
    Offset? photoPan,
  }) {
    return EditorState(
      inklings: inklings ?? this.inklings,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      tool: tool ?? this.tool,
      brushColor: brushColor ?? this.brushColor,
      brushSize: brushSize ?? this.brushSize,
      zoom: zoom ?? this.zoom,
      zoomEnabled: zoomEnabled ?? this.zoomEnabled,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isExporting: isExporting ?? this.isExporting,
      photoScale: photoScale ?? this.photoScale,
      photoPan: photoPan ?? this.photoPan,
    );
  }
}
