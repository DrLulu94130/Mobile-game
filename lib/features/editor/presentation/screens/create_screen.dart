import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import 'editor_screen.dart';

/// Entry point of the creation flow: pick a photo from the gallery or camera.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New challenge')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const StateMessage(
                    icon: Icons.photo_camera_back_outlined,
                    title: 'Choose a photo to hide in',
                    subtitle:
                        'Pick a busy, colourful scene — it makes camouflage more fun.',
                  ),
                  const SizedBox(height: 8),
                  _SourceCard(
                    icon: Icons.photo_library_outlined,
                    title: 'From gallery',
                    subtitle: 'Use one of your own pictures',
                    onTap: () => _pick(ImageSource.gallery),
                  ),
                  const SizedBox(height: 12),
                  _SourceCard(
                    icon: Icons.photo_camera_outlined,
                    title: 'Take a photo',
                    subtitle: 'Snap something right now',
                    onTap: () => _pick(ImageSource.camera),
                  ),
                ],
              ),
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
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
