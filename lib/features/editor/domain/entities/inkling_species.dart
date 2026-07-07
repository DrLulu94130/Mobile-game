import 'package:flutter/foundation.dart';

/// The visual family an Inkling belongs to. Every species is an original
/// design — round, simple, white-bodied creatures with large eyes.
enum InklingSpecies {
  classic('Classic', 'assets/packs/classic.json', premium: false),
  ghost('Ghosts', 'assets/packs/ghost.json', premium: true),
  robot('Robots', 'assets/packs/robot.json', premium: true),
  dragon('Dragons', 'assets/packs/dragon.json', premium: true),
  alien('Aliens', 'assets/packs/alien.json', premium: true),
  animal('Animals', 'assets/packs/animal.json', premium: true),
  monster('Monsters', 'assets/packs/monster.json', premium: true);

  const InklingSpecies(this.label, this.asset, {required this.premium});

  final String label;
  final String asset;

  /// Whether the pack is gated behind a Premium subscription.
  final bool premium;

  static InklingSpecies fromName(String? name) {
    return InklingSpecies.values.firstWhere(
      (s) => s.name == name,
      orElse: () => InklingSpecies.classic,
    );
  }
}

/// Descriptor for a single selectable creature inside a pack.
@immutable
class InklingVariant {
  const InklingVariant({
    required this.id,
    required this.species,
    required this.name,
  });

  final String id;
  final InklingSpecies species;
  final String name;

  bool get isPremium => species.premium;
}
