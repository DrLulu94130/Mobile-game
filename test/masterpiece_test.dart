import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/features/editor/domain/masterpieces.dart';
import 'package:inkognito/features/editor/presentation/painters/masterpiece_painter.dart';

void main() {
  test('there is a distinct painter style for every masterpiece', () {
    // Guards against adding an enum value without a paint branch.
    for (final style in MasterpieceStyle.values) {
      expect(MasterpiecePainter(style).style, style);
    }
    expect(MasterpieceStyle.values.length, 6);
  });

  testWidgets('every masterpiece renders to non-empty PNG bytes',
      (tester) async {
    // Picture.toImage needs the real async engine, hence runAsync.
    await tester.runAsync(() async {
      for (final style in MasterpieceStyle.values) {
        final bytes = await MasterpiecePainter.render(
          style,
          width: 108,
          height: 192,
        );
        // A valid PNG starts with the 8-byte signature and has real content.
        expect(
          bytes.length,
          greaterThan(100),
          reason: '$style produced no data',
        );
        expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      }
    });
  });

  test('repainting is only needed when the style changes', () {
    const a = MasterpiecePainter(MasterpieceStyle.starryNight);
    const b = MasterpiecePainter(MasterpieceStyle.greatWave);
    expect(a.shouldRepaint(a), isFalse);
    expect(a.shouldRepaint(b), isTrue);
  });
}
