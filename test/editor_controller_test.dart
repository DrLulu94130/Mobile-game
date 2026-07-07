import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/features/editor/domain/entities/inkling_species.dart';
import 'package:inkognito/features/editor/presentation/state/editor_controller.dart';

void main() {
  group('EditorController', () {
    test('adds and selects an Inkling', () {
      final c = EditorController();
      c.addInkling(InklingSpecies.classic);
      expect(c.state.inklings.length, 1);
      expect(c.state.selectedId, c.state.inklings.first.id);
    });

    test('duplicate creates a distinct Inkling with a new id', () {
      final c = EditorController();
      c.addInkling(InklingSpecies.ghost);
      final firstId = c.state.inklings.first.id;
      c.duplicateSelected();
      expect(c.state.inklings.length, 2);
      expect(c.state.inklings[1].id, isNot(firstId));
      expect(c.state.inklings[1].species, InklingSpecies.ghost);
    });

    test('delete removes the selected Inkling', () {
      final c = EditorController();
      c.addInkling(InklingSpecies.robot);
      c.deleteSelected();
      expect(c.state.inklings, isEmpty);
      expect(c.state.selectedId, isNull);
    });

    test('undo and redo restore history', () {
      final c = EditorController();
      c.addInkling(InklingSpecies.classic);
      c.addInkling(InklingSpecies.alien);
      expect(c.state.inklings.length, 2);

      c.undo();
      expect(c.state.inklings.length, 1);

      c.redo();
      expect(c.state.inklings.length, 2);
    });

    test('drawing appends a stroke to the selected Inkling', () {
      final c = EditorController();
      c.addInkling(InklingSpecies.classic);
      c.beginStroke(const Offset(0.5, 0.5));
      c.extendStroke(const Offset(0.6, 0.6));
      c.endStroke();
      expect(c.state.inklings.first.strokes.length, 1);
      expect(c.state.inklings.first.strokes.first.points.length, 2);
    });

    test('move clamps the centre within the canvas', () {
      final c = EditorController();
      c.addInkling(InklingSpecies.classic);
      c.moveSelected(const Offset(5, 5));
      c.endTransform();
      final center = c.state.inklings.first.center;
      expect(center.dx, lessThanOrEqualTo(1.0));
      expect(center.dy, lessThanOrEqualTo(1.0));
    });
  });
}
