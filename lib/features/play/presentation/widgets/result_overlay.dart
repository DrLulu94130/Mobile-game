import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';

/// End-of-game overlay showing the score breakdown and the revealed solution.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    required this.found,
    required this.total,
    required this.durationMs,
    required this.score,
    required this.revealUrl,
    required this.onReplay,
    required this.onDone,
    super.key,
  });

  final int found;
  final int total;
  final int durationMs;
  final int score;
  final String revealUrl;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final perfect = found == total;
    final seconds = (durationMs / 1000).toStringAsFixed(1);
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                perfect ? l.perfect : l.roundOver,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DarkStat(value: '$found/$total', label: l.found),
                  _DarkStat(value: '${seconds}s', label: l.time),
                  _DarkStat(value: '$score', label: l.score),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l.theSolution,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: revealUrl,
                  height: 240,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: l.playAgain,
                icon: Icons.replay,
                onPressed: onReplay,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDone,
                child: Text(
                  l.done,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkStat extends StatelessWidget {
  const _DarkStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.splash,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
