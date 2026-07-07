import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';

/// Social networks Inkognito can share to directly.
enum ShareTarget {
  instagramStory('Instagram', 'com.instagram.android', 'instagram-stories://share'),
  snapchat('Snapchat', 'com.snapchat.android', 'snapchat://'),
  tiktok('TikTok', 'com.zhiliaoapp.musically', 'snssdk1233://'),
  whatsapp('WhatsApp', 'com.whatsapp', 'whatsapp://'),
  messages('Messages', null, 'sms:'),
  copyLink('Copy link', null, null);

  const ShareTarget(this.label, this.androidPackage, this.scheme);
  final String label;
  final String? androidPackage;
  final String? scheme;
}

/// Builds share links and hands the camouflaged image to the OS/social apps.
///
/// The shared media contains **only the camouflaged photo**. The deep link
/// opens the challenge in-app, or falls back to the store if not installed.
class ShareService {
  const ShareService();

  /// The universal/deep link that opens a specific challenge.
  String challengeLink(String challengeId) =>
      'https://${Env.dynamicLinkHost}/c/$challengeId';

  /// Writes bytes to a temp file so they can be attached to a share sheet.
  Future<File> _writeTemp(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Shares the camouflaged image + link. For [ShareTarget.copyLink] the link
  /// is copied to the clipboard instead.
  Future<void> share({
    required ShareTarget target,
    required Uint8List camouflagedImage,
    required String challengeId,
    required String title,
  }) async {
    final link = challengeLink(challengeId);

    if (target == ShareTarget.copyLink) {
      await Clipboard.setData(ClipboardData(text: link));
      return;
    }

    final file = await _writeTemp(camouflagedImage, 'inkognito_$challengeId.jpg');

    // Try a direct hand-off to the target app; on failure fall back to the
    // system share sheet so the user can still pick another app.
    final scheme = target.scheme;
    if (scheme != null && await _canLaunch(scheme)) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Find the hidden Inklings! $link',
        subject: title,
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Can you find them? $title — $link',
    );
  }

  Future<bool> _canLaunch(String scheme) async {
    try {
      return await canLaunchUrl(Uri.parse(scheme));
    } catch (_) {
      return false;
    }
  }

  /// Opens the appropriate store listing when a recipient lacks the app.
  Future<void> openStore() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id${Env.appStoreId}')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=${Env.androidPackage}',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => const ShareService(),
);
