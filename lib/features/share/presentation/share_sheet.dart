import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../challenge/domain/entities/challenge.dart';
import '../data/share_service.dart';

/// Bottom sheet shown after publishing: previews the camouflaged image and
/// offers direct share targets. Only the camouflaged photo is shared.
class ShareSheet extends ConsumerWidget {
  const ShareSheet({
    required this.challenge,
    required this.camouflagedBytes,
    super.key,
  });

  final Challenge challenge;
  final Uint8List camouflagedBytes;

  static const _targets = [
    (ShareTarget.instagramStory, Icons.camera_alt, AppColors.coral),
    (ShareTarget.snapchat, Icons.chat_bubble, AppColors.glow),
    (ShareTarget.tiktok, Icons.music_note, AppColors.textStrong),
    (ShareTarget.whatsapp, Icons.chat, AppColors.success),
    (ShareTarget.messages, Icons.sms, AppColors.splash),
    (ShareTarget.copyLink, Icons.link, AppColors.ink),
  ];

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    ShareTarget t,
  ) async {
    await ref.read(shareServiceProvider).share(
          target: t,
          camouflagedImage: camouflagedBytes,
          challengeId: challenge.id,
          title: challenge.title,
        );
    if (context.mounted && t == ShareTarget.copyLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).linkCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.challengePublished,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(l.shareSubtitle),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                camouflagedBytes,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: [
                for (final (target, icon, color) in _targets)
                  _ShareButton(
                    label: target.label,
                    icon: icon,
                    color: color,
                    onTap: () => _share(context, ref, target),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(Routes.challengePath(challenge.id));
              },
              child: Text(l.viewChallenge),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
