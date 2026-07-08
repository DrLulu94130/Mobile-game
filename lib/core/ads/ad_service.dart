import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad unit identifiers. Defaults are Google's official **test** units so the
/// Free tier shows ads out of the box without risking policy violations.
/// Provide real ids via `--dart-define` for release builds.
abstract class AdUnits {
  static bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return true;
    }
  }

  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialTest =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _bannerOverride = String.fromEnvironment('ADMOB_BANNER');
  static const String _interstitialOverride =
      String.fromEnvironment('ADMOB_INTERSTITIAL');

  static String get banner {
    if (_bannerOverride.isNotEmpty) return _bannerOverride;
    return _isAndroid ? _androidBannerTest : _iosBannerTest;
  }

  static String get interstitial {
    if (_interstitialOverride.isNotEmpty) return _interstitialOverride;
    return _isAndroid ? _androidInterstitialTest : _iosInterstitialTest;
  }
}

/// Initialises the Mobile Ads SDK and brokers interstitials.
///
/// Callers should always gate ad display on the user's Premium status — the
/// service itself stays agnostic so it can be unit-tested.
class AdService {
  AdService();

  bool _initialised = false;
  InterstitialAd? _interstitial;
  int _showsSincePublish = 0;

  Future<void> initialize() async {
    if (_initialised) return;
    try {
      await MobileAds.instance.initialize();
      _initialised = true;
      _preloadInterstitial();
    } catch (_) {
      // Ads are non-essential; never block the app on init failure.
    }
  }

  void _preloadInterstitial() {
    if (!_initialised) return;
    InterstitialAd.load(
      adUnitId: AdUnits.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Shows an interstitial if one is ready. No-op when not loaded, so the UX
  /// degrades gracefully. Reloads the next ad afterwards.
  Future<void> maybeShowInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _preloadInterstitial();
      },
    );
    await ad.show();
  }

  /// Frequency-caps interstitials to roughly one per few actions.
  bool shouldShowAfterAction() {
    _showsSincePublish++;
    if (_showsSincePublish >= 2) {
      _showsSincePublish = 0;
      return true;
    }
    return false;
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(service.dispose);
  return service;
});
