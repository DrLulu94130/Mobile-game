import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';

/// Thin wrapper over Firebase Storage for uploading challenge images.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadChallengeImage({
    required String challengeId,
    required Uint8List bytes,
    required bool revealed,
  }) async {
    final path = revealed
        ? AppConstants.challengeRevealPath(challengeId)
        : AppConstants.challengeImagePath(challengeId);
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _storage.ref(AppConstants.avatarPath(uid));
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(firebaseStorageProvider)),
);
