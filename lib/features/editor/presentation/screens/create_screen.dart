import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/masterpieces.dart';
import '../painters/masterpiece_painter.dart';
import 'editor_screen.dart';

/// Entry point of the creation flow: pick a photo from the gallery or camera,
/// or start from one of the ready-made famous canvases.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      context.pushReplacement(
        Routes.editor,
        extra: EditorArgs(photoBytes: bytes),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickMasterpiece(MasterpieceStyle style) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await MasterpiecePainter.render(style);
      if (!mounted) return;
      context.pushReplacement(
        Routes.editor,
        extra: EditorArgs(photoBytes: bytes),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _masterpieceName(AppLocalizations l, MasterpieceStyle style) {
    return switch (style) {
      MasterpieceStyle.starryNight => l.masterpieceStarryNight,
      MasterpieceStyle.greatWave => l.masterpieceGreatWave,
      MasterpieceStyle.waterLilies => l.masterpieceWaterLilies,
      MasterpieceStyle.scream => l.masterpieceScream,
      MasterpieceStyle.gridComposition => l.masterpieceGrid,
      MasterpieceStyle.goldenGarden => l.masterpieceGolden,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.newChallenge)),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                StateMessage(
                  icon: Icons.photo_camera_back_outlined,
                  title: l.choosePhotoTitle,
                  subtitle: l.choosePhotoBody,
                ),
                const SizedBox(height: 8),
                _SourceCard(
                  icon: Icons.photo_library_outlined,
                  title: l.fromGallery,
                  subtitle: l.fromGallerySub,
                  onTap: () => _pick(ImageSource.gallery),
                ),
                const SizedBox(height: 12),
                _SourceCard(
                  icon: Icons.photo_camera_outlined,
                  title: l.takePhoto,
                  subtitle: l.takePhotoSub,
                  onTap: () => _pick(ImageSource.camera),
                ),
                const SizedBox(height: 24),
                Text(
                  l.masterpiecesTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.masterpiecesSub,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: MasterpieceStyle.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final style = MasterpieceStyle.values[i];
                      return _MasterpieceCard(
                        style: style,
                        name: _masterpieceName(l, style),
                        onTap: () => _pickMasterpiece(style),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Live-painted preview of a famous canvas, ready to hide Inklings in.
class _MasterpieceCard extends StatelessWidget {
  const _MasterpieceCard({
    required this.style,
    required this.name,
    required this.onTap,
  });

  final MasterpieceStyle style;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: MasterpiecePainter(style),
              size: const Size(92, 162),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 92,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.ink.withValues(alpha: 0.14),
          child: Icon(icon, color: AppColors.ink),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
