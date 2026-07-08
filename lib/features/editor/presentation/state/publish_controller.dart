import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../challenge/data/image_export_service.dart';
import '../../../challenge/data/storage_service.dart';
import '../../../challenge/domain/entities/challenge.dart';
import '../../../economy/data/token_service.dart';
import '../../../progression/data/progression_service.dart';
import '../../domain/entities/placed_inkling.dart';
import '../../domain/photo_framing.dart';

/// Immutable output of a successful publish.
class PublishOutput {
  const PublishOutput({
    required this.challenge,
    required this.camouflagedBytes,
    required this.revealedBytes,
  });

  final Challenge challenge;
  final Uint8List camouflagedBytes;
  final Uint8List revealedBytes;
}

/// Renders the final images, uploads them and creates the Firestore challenge,
/// then awards XP for authoring. Exposed as an [AsyncValue] for the UI.
class PublishController extends AutoDisposeAsyncNotifier<PublishOutput?> {
  @override
  Future<PublishOutput?> build() async => null;

  Future<Result<PublishOutput>> publish({
    required Uint8List photoBytes,
    required List<PlacedInkling> inklings,
    required String title,
    required bool isPublic,
    bool hd = false,
    bool chargeTokens = true,
    double photoScale = 1.0,
    Offset photoPan = Offset.zero,
  }) async {
    state = const AsyncLoading();
    var charged = false;
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        return const Err(ValidationFailure('You must be signed in'));
      }

      // Posting costs tokens (Premium publishes for free). Charged up front
      // so a failed balance never uploads images.
      if (chargeTokens) {
        final paid = await ref
            .read(tokenServiceProvider)
            .trySpend(user.uid, AppConstants.tokensToPublish);
        if (!paid) {
          const failure = ValidationFailure('Not enough tokens');
          state = AsyncError(failure, StackTrace.current);
          return const Err(failure);
        }
        charged = true;
      }

      final export = ref.read(imageExportServiceProvider);
      final ui.Image photo = await export.decode(photoBytes);

      final camouflaged = await export.render(
        photo: photo,
        inklings: inklings,
        revealed: false,
        hd: hd,
        photoScale: photoScale,
        photoPan: photoPan,
      );
      final revealed = await export.render(
        photo: photo,
        inklings: inklings,
        revealed: true,
        hd: hd,
        photoScale: photoScale,
        photoPan: photoPan,
      );

      final repo = ref.read(challengeRepositoryProvider);
      final storage = ref.read(storageServiceProvider);
      final id = repo.newId();

      final camoUrl = await storage.uploadChallengeImage(
        challengeId: id,
        bytes: camouflaged,
        revealed: false,
      );
      final revealUrl = await storage.uploadChallengeImage(
        challengeId: id,
        bytes: revealed,
        revealed: true,
      );

      final profile = await ref.read(currentUserProvider.future);
      final challenge = Challenge(
        id: id,
        authorId: user.uid,
        authorName: profile?.displayName ?? 'Player',
        authorAvatarUrl: profile?.avatarUrl,
        title: title.trim().isEmpty ? 'Untitled' : title.trim(),
        camouflagedImageUrl: camoUrl,
        revealedImageUrl: revealUrl,
        inklings: inklings,
        canvasAspectRatio: PhotoFraming.canvasAspect,
        createdAt: DateTime.now(),
        isPublic: isPublic,
        difficulty: _difficulty(inklings),
      );

      final created = await repo.create(challenge);
      photo.dispose();

      switch (created) {
        case Success(value: final c):
          // Award XP for authoring (best-effort).
          await ref.read(progressionServiceProvider).awardXp(
                uid: user.uid,
                xpDelta: AppConstants.xpPerChallengeCreated,
                challengesCreatedDelta: 1,
              );
          final output = PublishOutput(
            challenge: c,
            camouflagedBytes: camouflaged,
            revealedBytes: revealed,
          );
          state = AsyncData(output);
          return Success(output);
        case Err(failure: final f):
          await _refund(charged);
          state = AsyncError(f, StackTrace.current);
          return Err(f);
      }
    } catch (e, st) {
      await _refund(charged);
      state = AsyncError(e, st);
      return Err(UnknownFailure(e.toString()));
    }
  }

  /// Returns the publish fee when the challenge never made it online.
  Future<void> _refund(bool charged) async {
    if (!charged) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      await ref
          .read(tokenServiceProvider)
          .earn(user.uid, AppConstants.tokensToPublish);
    } catch (_) {
      // Best-effort: losing the refund is preferable to crashing the flow.
    }
  }

  /// Difficulty 1..5 from Inkling count and average camouflage density.
  int _difficulty(List<PlacedInkling> inklings) {
    if (inklings.isEmpty) return 1;
    final avgStrokes =
        inklings.map((i) => i.strokes.length).reduce((a, b) => a + b) /
            inklings.length;
    final byCount = (inklings.length / 2).ceil();
    final byCamo = avgStrokes >= 6 ? 2 : (avgStrokes >= 2 ? 1 : 0);
    return (byCount + byCamo).clamp(1, 5);
  }
}

final publishControllerProvider =
    AutoDisposeAsyncNotifierProvider<PublishController, PublishOutput?>(
  PublishController.new,
);
