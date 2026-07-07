import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../community/presentation/widgets/challenge_card.dart';

/// "Challenges of the day" — the top public challenges created today.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyChallengesProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            title: Text('Daily', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.today, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's picks",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fresh puzzles, updated every day. Keep your streak alive!',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          daily.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: StateMessage(
                icon: Icons.error_outline,
                title: 'Could not load',
                subtitle: '$e',
              ),
            ),
            data: (list) => list.isEmpty
                ? const SliverFillRemaining(
                    child: StateMessage(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Nothing yet today',
                      subtitle: 'Check back later or create the first one.',
                    ),
                  )
                : SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => ChallengeCard(challenge: list[i]),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
