import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../editor/domain/entities/inkling_species.dart';
import '../../../premium/data/purchase_repository.dart';
import '../../../../shared/widgets/inkling_avatar.dart';

/// Showcase of every character pack. Premium packs are locked until purchase.
class PacksScreen extends ConsumerWidget {
  const PacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).characterPacks)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final species in InklingSpecies.values)
            _PackRow(species: species, locked: species.premium && !premium),
        ],
      ),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({required this.species, required this.locked});
  final InklingSpecies species;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Opacity(
              opacity: locked ? 0.5 : 1,
              child: InklingAvatar(species: species, size: 64),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    species.premium
                        ? 'Premium pack · original designs'
                        : 'Free · original designs',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (locked)
              FilledButton.tonalIcon(
                onPressed: () => context.push(Routes.premium),
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('Unlock'),
              )
            else
              const Icon(Icons.check_circle, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
