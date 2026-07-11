import 'package:flutter/material.dart';

import '../../features/editor/domain/entities/inkling_species.dart';
import '../../features/editor/domain/entities/placed_inkling.dart';
import '../../features/editor/presentation/painters/inkling_painter.dart';

/// A small, static preview of an Inkling of a given [species]. Used in pack
/// pickers, onboarding and empty states.
class InklingAvatar extends StatelessWidget {
  const InklingAvatar({required this.species, this.size = 64, super.key});

  final InklingSpecies species;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inkling = PlacedInkling(
      id: 'preview-${species.name}',
      species: species,
      variantId: 'default',
      center: const Offset(0.5, 0.5),
      size: 1,
      rotation: 0,
    );
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: InklingPainter(inkling: inkling)),
    );
  }
}
