import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/draw_stroke.dart';
import '../../domain/entities/inkling_species.dart';
import '../../domain/entities/placed_inkling.dart';
import 'editor_state.dart';

const _uuid = Uuid();

/// Manages the editor canvas: placing, transforming and painting Inklings,
/// plus a full undo/redo history.
class EditorController extends StateNotifier<EditorState> {
  EditorController()
      : super(const EditorState(inklings: [])) {
    _pushHistory();
  }

  /// Public read-only view of the current state for gesture handlers that need
  /// the freshest value mid-interaction (before a widget rebuild).
  EditorState get snapshot => state;

  final List<List<PlacedInkling>> _undo = [];
  final List<List<PlacedInkling>> _redo = [];

  static const int _maxInklings = 12; // enforced against entitlement upstream

  // --- Tools ---

  void setTool(EditorTool tool) => state = state.copyWith(tool: tool);
  void setBrushColor(Color color) => state = state.copyWith(brushColor: color);
  void setBrushSize(double size) =>
      state = state.copyWith(brushSize: size.clamp(0.01, 0.3));
  void setZoom(double zoom) =>
      state = state.copyWith(zoom: zoom.clamp(1.0, 4.0));

  void select(String? id) {
    if (id == null) {
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedId: id);
    }
  }

  // --- Placement ---

  void addInkling(InklingSpecies species, {String variantId = 'default'}) {
    if (state.inklings.length >= _maxInklings) return;
    final inkling = PlacedInkling(
      id: _uuid.v4(),
      species: species,
      variantId: variantId,
      center: const Offset(0.5, 0.5),
      size: 0.22,
      rotation: 0,
    );
    _commit([...state.inklings, inkling], select: inkling.id);
  }

  void duplicateSelected() {
    final sel = state.selected;
    if (sel == null) return;
    final copy = sel.copyWith(
      center: Offset(
        (sel.center.dx + 0.06).clamp(0.05, 0.95),
        (sel.center.dy + 0.06).clamp(0.05, 0.95),
      ),
    );
    // copyWith keeps the same id; assign a fresh one.
    final clone = PlacedInkling(
      id: _uuid.v4(),
      species: copy.species,
      variantId: copy.variantId,
      center: copy.center,
      size: copy.size,
      rotation: copy.rotation,
      strokes: List.of(copy.strokes),
    );
    _commit([...state.inklings, clone], select: clone.id);
  }

  void deleteSelected() {
    final id = state.selectedId;
    if (id == null) return;
    _commit(
      state.inklings.where((i) => i.id != id).toList(),
      clearSelection: true,
    );
  }

  // --- Live transforms (no history until the gesture ends) ---

  void moveSelected(Offset deltaNormalised) {
    _mutateSelected((i) => i.copyWith(
          center: Offset(
            (i.center.dx + deltaNormalised.dx).clamp(0.0, 1.0),
            (i.center.dy + deltaNormalised.dy).clamp(0.0, 1.0),
          ),
        ));
  }

  void scaleSelected(double factor) {
    _mutateSelected(
      (i) => i.copyWith(size: (i.size * factor).clamp(0.05, 0.9)),
    );
  }

  void rotateSelected(double deltaRadians) {
    _mutateSelected(
      (i) => i.copyWith(rotation: i.rotation + deltaRadians),
    );
  }

  /// Directly set transform (used by the two-finger gesture handler).
  void transformSelected({Offset? center, double? size, double? rotation}) {
    _mutateSelected((i) => i.copyWith(
          center: center == null
              ? null
              : Offset(center.dx.clamp(0, 1), center.dy.clamp(0, 1)),
          size: size?.clamp(0.05, 0.9),
          rotation: rotation,
        ));
  }

  /// Call when a drag/scale gesture completes to snapshot the result.
  void endTransform() => _pushHistory();

  // --- Drawing ---

  DrawStroke? _activeStroke;

  /// Begins a stroke at a point in the selected Inkling's local space (0..1).
  void beginStroke(Offset localPoint) {
    final sel = state.selected;
    if (sel == null) return;
    final isEraser = state.tool == EditorTool.eraser;
    _activeStroke = DrawStroke(
      points: [localPoint],
      color: state.brushColor,
      width: state.brushSize,
      isEraser: isEraser,
    );
    _applyActiveStroke(sel.id, replaceLast: false);
  }

  void extendStroke(Offset localPoint) {
    if (_activeStroke == null) return;
    _activeStroke = _activeStroke!.copyWith(
      points: [..._activeStroke!.points, localPoint],
    );
    final sel = state.selected;
    if (sel != null) _applyActiveStroke(sel.id, replaceLast: true);
  }

  void endStroke() {
    if (_activeStroke == null) return;
    _activeStroke = null;
    _pushHistory();
  }

  void _applyActiveStroke(String id, {required bool replaceLast}) {
    final updated = state.inklings.map((i) {
      if (i.id != id) return i;
      final strokes = List<DrawStroke>.of(i.strokes);
      if (replaceLast && strokes.isNotEmpty) {
        strokes[strokes.length - 1] = _activeStroke!;
      } else {
        strokes.add(_activeStroke!);
      }
      return i.copyWith(strokes: strokes);
    }).toList();
    state = state.copyWith(inklings: updated);
  }

  // --- Undo / Redo ---

  void undo() {
    if (_undo.length < 2) return;
    _redo.add(_undo.removeLast());
    state = state.copyWith(
      inklings: _clone(_undo.last),
      canUndo: _undo.length > 1,
      canRedo: true,
    );
  }

  void redo() {
    if (_redo.isEmpty) return;
    final next = _redo.removeLast();
    _undo.add(next);
    state = state.copyWith(
      inklings: _clone(next),
      canUndo: true,
      canRedo: _redo.isNotEmpty,
    );
  }

  // --- Internal helpers ---

  void _mutateSelected(PlacedInkling Function(PlacedInkling) transform) {
    final id = state.selectedId;
    if (id == null) return;
    state = state.copyWith(
      inklings: state.inklings
          .map((i) => i.id == id ? transform(i) : i)
          .toList(),
    );
  }

  void _commit(
    List<PlacedInkling> inklings, {
    String? select,
    bool clearSelection = false,
  }) {
    state = state.copyWith(
      inklings: inklings,
      selectedId: select,
      clearSelection: clearSelection,
    );
    _pushHistory();
  }

  void _pushHistory() {
    _undo.add(_clone(state.inklings));
    _redo.clear();
    // Cap history to keep memory bounded.
    if (_undo.length > 50) _undo.removeAt(0);
    state = state.copyWith(canUndo: _undo.length > 1, canRedo: false);
  }

  List<PlacedInkling> _clone(List<PlacedInkling> source) =>
      source.map((i) => i.copyWith(strokes: List.of(i.strokes))).toList();

  /// Loads an existing challenge's Inklings into the editor.
  void hydrate(List<PlacedInkling> inklings) {
    _undo.clear();
    _redo.clear();
    state = EditorState(inklings: _clone(inklings));
    _pushHistory();
  }
}

final editorControllerProvider =
    StateNotifierProvider.autoDispose<EditorController, EditorState>(
  (ref) => EditorController(),
);

/// Utility: rotate a point around a pivot, used to map screen taps into an
/// Inkling's local (unrotated) space.
Offset rotatePoint(Offset point, Offset pivot, double radians) {
  final s = math.sin(radians);
  final c = math.cos(radians);
  final dx = point.dx - pivot.dx;
  final dy = point.dy - pivot.dy;
  return Offset(
    pivot.dx + dx * c - dy * s,
    pivot.dy + dx * s + dy * c,
  );
}
