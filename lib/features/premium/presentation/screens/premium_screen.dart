import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/purchase_repository.dart';

/// The Premium paywall: benefits, RevenueCat packages and restore.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;

  static const _benefits = [
    ('No ads', Icons.block, 'Enjoy an uninterrupted experience'),
    ('All packs', Icons.pets, 'Ghosts, robots, dragons, aliens & more'),
    ('HD export', Icons.high_quality, 'Share crisp, high-resolution puzzles'),
    ('Unlimited challenges', Icons.all_inclusive, 'Create as many as you like'),
    ('Up to 12 Inklings', Icons.groups, 'Build harder, denser puzzles'),
    ('Exclusive packs', Icons.star, 'Seasonal creatures just for members'),
  ];

  Future<void> _purchase(Package package) async {
    setState(() => _busy = true);
    try {
      final ok = await ref.read(purchaseRepositoryProvider).purchase(package);
      if (!mounted) return;
      if (ok) {
        ref.invalidate(isPremiumProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).welcomePremium)),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).purchaseCancelled),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final offerings = ref.watch(offeringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.premiumTitle),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await ref.read(purchaseRepositoryProvider).restore();
              if (mounted && ok) ref.invalidate(isPremiumProvider);
            },
            child: Text(l.restore),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  color: AppColors.glow,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  l.unlockEverything,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  l.unlockSub,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final (title, icon, sub) in _benefits)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.ink.withValues(alpha: 0.15),
                child: Icon(icon, color: AppColors.ink),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(sub),
            ),
          const SizedBox(height: 12),
          offerings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _FallbackCta(busy: _busy),
            data: (packages) {
              if (packages.isEmpty) return _FallbackCta(busy: _busy);
              return Column(
                children: [
                  for (final p in packages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GradientButton(
                        label:
                            '${p.storeProduct.title} · ${p.storeProduct.priceString}',
                        loading: _busy,
                        onPressed: () => _purchase(p),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Subscriptions renew automatically unless cancelled. '
            'Manage in your store account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FallbackCta extends StatelessWidget {
  const _FallbackCta({required this.busy});
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      label: AppLocalizations.of(context).goPremium,
      loading: busy,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store not configured in this build.')),
        );
      },
    );
  }
}
