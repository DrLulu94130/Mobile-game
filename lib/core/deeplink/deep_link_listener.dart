import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';

/// Listens for incoming deep links / universal links and routes them into the
/// app. Handles both the cold-start link and links received while running.
///
/// Supported forms:
///   * `inkognito://challenge/<id>`
///   * `https://<host>/c/<id>`  (served by the openChallenge Cloud Function)
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Cold start: an link that launched the app.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {
      // No initial link or platform without support (e.g. tests).
    }
    // Warm links while the app is running.
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final id = DeepLinkParser.challengeId(uri);
    if (id == null) return;
    // Defer to the next frame so the router is ready during cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.router.push(Routes.challengePath(id));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pure parser that pulls a challenge id from any supported link shape.
/// Extracted so it can be unit-tested independently of platform channels.
abstract class DeepLinkParser {
  static String? challengeId(Uri uri) {
    final segments = uri.pathSegments;
    // https://host/c/<id>
    if (segments.length >= 2 && segments[segments.length - 2] == 'c') {
      return segments.last;
    }
    // inkognito://challenge/<id>  → host == 'challenge', first segment == id
    if (uri.scheme == 'inkognito' && uri.host == 'challenge') {
      if (segments.isNotEmpty) return segments.last;
    }
    // inkognito://challenge?id=<id>
    final queryId = uri.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) return queryId;
    return null;
  }
}
