import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/entities/badge.dart' as domain;

/// Full gallery of achievement badges with earned/locked state.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned =
        ref.watch(currentUserProvider).valueOrNull?.badgeIds ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [
          for (final badge in domain.BadgeCatalog.all)
            _BadgeCard(badge: badge, earned: earned.contains(badge.id)),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.earned});
  final domain.Badge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: earned
              ? badge.color.withValues(alpha: 0.4)
              : AppColors.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: earned
                  ? badge.color.withValues(alpha: 0.18)
                  : AppColors.textMuted.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              earned ? badge.icon : Icons.lock_outline,
              color: earned ? badge.color : AppColors.textMuted,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
