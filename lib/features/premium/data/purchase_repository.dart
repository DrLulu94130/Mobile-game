import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/env.dart';

/// Wraps RevenueCat to expose Premium entitlement state and purchase flows.
class PurchaseRepository {
  const PurchaseRepository();

  /// Whether the current user has the active `premium` entitlement.
  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(Env.premiumEntitlement);
    } catch (_) {
      return false;
    }
  }

  /// Fetches the current offering's available packages.
  Future<List<Package>> packages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Purchases a package; returns true if Premium is now active.
  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.entitlements.active
          .containsKey(Env.premiumEntitlement);
    } on PlatformException {
      rethrow;
    }
  }

  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(Env.premiumEntitlement);
    } catch (_) {
      return false;
    }
  }

  /// Links the RevenueCat customer to the app's user id.
  Future<void> identify(String uid) async {
    try {
      await Purchases.logIn(uid);
    } catch (_) {
      // Non-fatal.
    }
  }
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => const PurchaseRepository(),
);

/// Reactive premium status. Falls back to the Firestore profile flag when
/// RevenueCat is unavailable (e.g. no keys configured in dev).
final isPremiumProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(purchaseRepositoryProvider).isPremium();
});

final offeringsProvider = FutureProvider.autoDispose<List<Package>>(
  (ref) => ref.watch(purchaseRepositoryProvider).packages(),
);
