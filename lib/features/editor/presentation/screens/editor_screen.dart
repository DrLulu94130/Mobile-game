import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import '../../../../core/ads/ad_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../economy/data/token_service.dart';
import '../../../premium/data/purchase_repository.dart';
import '../../../share/presentation/share_sheet.dart';
import '../../domain/entities/inkling_species.dart';
import '../../domain/entities/placed_inkling.dart';
import '../../domain/photo_framing.dart';
import '../state/editor_controller.dart';
import '../state/editor_state.dart';
import '../state/publish_controller.dart';
import 'pose_booth_screen.dart';
import '../widgets/editor_canvas.dart';
import '../widgets/editor_toolbars.dart';

/// Arguments passed into the editor route.
class EditorArgs {
  const EditorArgs({required this.photoBytes, this.initialInklings});
  final Uint8List photoBytes;
  final List<PlacedInkling>? initialInklings;
}

/// The full-screen Inkling editor: place, transform and camouflage creatures,
/// then publish the challenge.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({required this.args, super.key});
  final EditorArgs args;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  img.Image? _decodedPhoto; // for colour sampling
  late final ImageProvider _photoProvider;

  @override
  void initState() {
    super.initState();
    _photoProvider = MemoryImage(widget.args.photoBytes);
    _decodePhoto();
    if (widget.args.initialInklings != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(editorControllerProvider.notifier)
            .hydrate(widget.args.initialInklings!);
      });
    }
  }

  Future<void> _decodePhoto() async {
    // Decoding is CPU-bound; a microtask keeps the first frame responsive.
    final decoded = await Future(() => img.decodeImage(widget.args.photoBytes));
    if (mounted) setState(() => _decodedPhoto = decoded);
  }

  /// Aspect of the source photo (not the canvas — the canvas is always the
  /// story-style [PhotoFraming.canvasAspect]).
  double get _photoAspect {
    final p = _decodedPhoto;
    if (p == null) return 3 / 4;
    return p.width / p.height;
  }

  int get _maxInklings {
    final premium = ref.read(isPremiumProvider).valueOrNull ?? false;
    return premium
        ? AppConstants.premiumMaxInklingsPerChallenge
        : AppConstants.freeMaxInklingsPerChallenge;
  }

  // --- Colour sampling for pipette / auto-select ---

  /// Maps a normalised canvas point through the current photo framing and
  /// samples the photo pixel there.
  Color _sampleAt(Offset normalised) {
    final p = _decodedPhoto;
    if (p == null) return AppColors.ink;
    final s = ref.read(editorControllerProvider);
    final photoNorm = PhotoFraming.canvasNormToPhotoNorm(
      normalised,
      const Size(PhotoFraming.canvasAspect, 1),
      _photoAspect,
      s.photoScale,
      s.photoPan,
    );
    final x = (photoNorm.dx * p.width).clamp(0, p.width - 1).toInt();
    final y = (photoNorm.dy * p.height).clamp(0, p.height - 1).toInt();
    final px = p.getPixel(x, y);
    return Color.fromARGB(255, px.r.toInt(), px.g.toInt(), px.b.toInt());
  }

  /// Averages the photo colour under the selected Inkling for one-tap camo.
  Color _autoColorForSelected() {
    final p = _decodedPhoto;
    final sel = ref.read(editorControllerProvider).selected;
    if (p == null || sel == null) return AppColors.ink;
    var r = 0, g = 0, b = 0, n = 0;
    const samples = 24;
    for (var i = 0; i < samples; i++) {
      final angle = (i / samples) * 2 * math.pi;
      for (final f in const [0.3, 0.7]) {
        // Ring points in canvas-normalised space (the canvas is 9:16, so the
        // shortest side is the width; sizes are fractions of it).
        final ringNorm = Offset(
          sel.center.dx + (sel.size / 2) * f * math.cos(angle),
          sel.center.dy +
              (sel.size / 2) * f * math.sin(angle) * PhotoFraming.canvasAspect,
        );
        final c = _sampleAt(ringNorm);
        r += (c.r * 255).round();
        g += (c.g * 255).round();
        b += (c.b * 255).round();
        n++;
      }
    }
    if (n == 0) return AppColors.ink;
    return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
  }

  void _onSampleColor(Offset normalised) {
    final color = _sampleAt(normalised);
    final controller = ref.read(editorControllerProvider.notifier);
    controller.setBrushColor(color);
    controller.setTool(EditorTool.brush);
  }

  Future<void> _addInkling() async {
    final state = ref.read(editorControllerProvider);
    if (state.inklings.length >= _maxInklings) {
      _showLimitReached();
      return;
    }
    // Pose the 3D character first; the capture becomes the creature's body.
    final spriteId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PoseBoothScreen()),
    );
    if (spriteId == null || !mounted) return;
    ref
        .read(editorControllerProvider.notifier)
        .addInkling(InklingSpecies.classic, spriteId: spriteId);
  }

  void _showLimitReached() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: AppColors.ink),
            const SizedBox(height: 12),
            Text(
              l.inklingLimitTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l.inklingLimitBody(
                AppConstants.freeMaxInklingsPerChallenge,
                AppConstants.premiumMaxInklingsPerChallenge,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.premium);
              },
              child: Text(l.seePremium),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final state = ref.read(editorControllerProvider);
    if (!state.hasInklings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).addInklingFirst)),
      );
      return;
    }

    final premium = ref.read(isPremiumProvider).valueOrNull ?? false;

    // Posting costs tokens for free players — check the balance before any
    // rendering work so the refusal is instant.
    if (!premium) {
      final balance = ref.read(currentUserProvider).valueOrNull?.tokens ?? 0;
      if (balance < AppConstants.tokensToPublish) {
        _showNotEnoughTokens(balance);
        return;
      }
    }

    final title = await _askTitle();
    if (title == null || !mounted) return;

    final l = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref.read(publishControllerProvider.notifier).publish(
          photoBytes: widget.args.photoBytes,
          inklings: state.inklings,
          title: title,
          isPublic: true,
          hd: premium,
          chargeTokens: !premium,
          photoScale: state.photoScale,
          photoPan: state.photoPan,
        );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    await result.when(
      success: (output) async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => ShareSheet(
            challenge: output.challenge,
            camouflagedBytes: output.camouflagedBytes,
          ),
        );
        // Free tier: an interstitial after publishing (frequency-capped).
        if (!premium && ref.read(adServiceProvider).shouldShowAfterAction()) {
          await ref.read(adServiceProvider).maybeShowInterstitial();
        }
      },
      failure: (f) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.publishFailed(f.message))),
        );
      },
    );
  }

  void _showNotEnoughTokens(int balance) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.toll_rounded, size: 40, color: AppColors.splash),
            const SizedBox(height: 12),
            Text(
              l.notEnoughTokensTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l.notEnoughTokensBody(AppConstants.tokensToPublish, balance),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.push(Routes.discover);
              },
              icon: const Icon(Icons.swipe_up_rounded),
              label: Text(l.goDiscover),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await _watchAdForTokens();
              },
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l.watchAdForTokens(AppConstants.tokensPerRewardedAd)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _watchAdForTokens() async {
    final l = AppLocalizations.of(context);
    final ad = ref.read(adServiceProvider);
    if (!ad.isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.adNotReady)),
      );
      return;
    }
    final earned = await ad.showRewarded();
    if (!earned || !mounted) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(tokenServiceProvider)
        .earn(uid, AppConstants.tokensPerRewardedAd);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tokensEarned(AppConstants.tokensPerRewardedAd)),
        ),
      );
    }
  }

  Future<String?> _askTitle() {
    final controller = TextEditingController();
    final l = AppLocalizations.of(context);
    final premium = ref.read(isPremiumProvider).valueOrNull ?? false;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.nameYourChallenge),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(hintText: l.challengeHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              premium ? l.publish : l.publishCost(AppConstants.tokensToPublish),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context).toolBrush),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.canUndo ? controller.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: state.canRedo ? controller.redo : null,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _publish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.splash,
                minimumSize: const Size(64, 40),
              ),
              child: Text(AppLocalizations.of(context).done),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                // Story-style vertical stage, whatever the source photo.
                aspectRatio: PhotoFraming.canvasAspect,
                child: EditorCanvas(
                  photo: _photoProvider,
                  photoAspect: _photoAspect,
                  state: state,
                  controller: controller,
                  onSampleColor: _onSampleColor,
                ),
              ),
            ),
          ),
          EditorToolbars(
            state: state,
            controller: controller,
            onAdd: _addInkling,
            onAutoColor: () {
              final color = _autoColorForSelected();
              controller.setBrushColor(color);
              controller.setTool(EditorTool.brush);
            },
            onSampleFromCanvas: () => controller.setTool(EditorTool.eyedropper),
          ),
        ],
      ),
    );
  }
}
