import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../premium/data/purchase_repository.dart';
import '../../../share/presentation/share_sheet.dart';
import '../../domain/entities/inkling_species.dart';
import '../../domain/entities/placed_inkling.dart';
import '../state/editor_controller.dart';
import '../state/editor_state.dart';
import '../state/publish_controller.dart';
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

  double get _aspect {
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

  Color _sampleAt(Offset normalised) {
    final p = _decodedPhoto;
    if (p == null) return AppColors.ink;
    final x = (normalised.dx * p.width).clamp(0, p.width - 1).toInt();
    final y = (normalised.dy * p.height).clamp(0, p.height - 1).toInt();
    final px = p.getPixel(x, y);
    return Color.fromARGB(255, px.r.toInt(), px.g.toInt(), px.b.toInt());
  }

  /// Averages the photo colour under the selected Inkling for one-tap camo.
  Color _autoColorForSelected() {
    final p = _decodedPhoto;
    final sel = ref.read(editorControllerProvider).selected;
    if (p == null || sel == null) return AppColors.ink;
    final cx = sel.center.dx * p.width;
    final cy = sel.center.dy * p.height;
    final radius = (sel.size / 2) * math.min(p.width, p.height);
    var r = 0, g = 0, b = 0, n = 0;
    const samples = 24;
    for (var i = 0; i < samples; i++) {
      final angle = (i / samples) * 2 * math.pi;
      for (final f in const [0.3, 0.7]) {
        final x =
            (cx + radius * f * math.cos(angle)).clamp(0, p.width - 1).toInt();
        final y =
            (cy + radius * f * math.sin(angle)).clamp(0, p.height - 1).toInt();
        final px = p.getPixel(x, y);
        r += px.r.toInt();
        g += px.g.toInt();
        b += px.b.toInt();
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

  void _addInkling(InklingSpecies species) {
    final state = ref.read(editorControllerProvider);
    if (state.inklings.length >= _maxInklings) {
      _showLimitReached();
      return;
    }
    ref.read(editorControllerProvider.notifier).addInkling(species);
  }

  void _showLimitReached() {
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
              'Inkling limit reached',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Free challenges allow up to '
              '${AppConstants.freeMaxInklingsPerChallenge} Inklings. '
              'Go Premium to hide up to '
              '${AppConstants.premiumMaxInklingsPerChallenge}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.premium);
              },
              child: const Text('See Premium'),
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
        const SnackBar(content: Text('Add at least one Inkling first')),
      );
      return;
    }
    final title = await _askTitle();
    if (title == null || !mounted) return;

    final premium = ref.read(isPremiumProvider).valueOrNull ?? false;

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
        );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    result.when(
      success: (output) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => ShareSheet(
            challenge: output.challenge,
            camouflagedBytes: output.camouflagedBytes,
          ),
        );
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publish failed: ${f.message}')),
        );
      },
    );
  }

  Future<String?> _askTitle() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name your challenge'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'e.g. Spot the six!'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Publish'),
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
        title: const Text('Camouflage'),
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
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _aspect,
                child: EditorCanvas(
                  photo: _photoProvider,
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
            onAddInkling: _addInkling,
            onAutoColor: () {
              final color = _autoColorForSelected();
              controller.setBrushColor(color);
              controller.setTool(EditorTool.brush);
            },
            onSampleFromCanvas: () =>
                controller.setTool(EditorTool.eyedropper),
          ),
        ],
      ),
    );
  }
}
