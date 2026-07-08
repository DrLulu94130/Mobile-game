import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/app_user.dart';

/// Handles authentication and the user profile document in Firestore.
class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  User? get currentUser => _auth.currentUser;

  /// Streams the [AppUser] profile for the currently signed-in account, or
  /// `null` when signed out.
  Stream<AppUser?> watchProfile() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _users.doc(user.uid).snapshots().map((doc) {
        if (!doc.exists) {
          return AppUser(
            uid: user.uid,
            displayName: user.displayName ?? 'Player',
            email: user.email,
            avatarUrl: user.photoURL,
            isAnonymous: user.isAnonymous,
          );
        }
        return AppUser.fromJson(doc.id, doc.data()!);
      });
    });
  }

  /// Signs in anonymously so a user can play immediately, then ensures a
  /// profile document exists.
  Future<Result<AppUser>> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = await _ensureProfile(cred.user!, displayName: 'Player');
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Sign-in failed'));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Future<Result<AppUser>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _ensureProfile(cred.user!);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Future<Result<AppUser>> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      final user = await _ensureProfile(cred.user!, displayName: displayName);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Creates the Firestore profile document on first sign-in.
  Future<AppUser> _ensureProfile(User user, {String? displayName}) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) {
      return AppUser.fromJson(snap.id, snap.data()!);
    }
    final profile = AppUser(
      uid: user.uid,
      displayName: displayName ?? user.displayName ?? 'Player',
      email: user.email,
      avatarUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
    await ref.set({
      ...profile.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return profile;
  }

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Incorrect email or password',
      'email-already-in-use' => 'That email is already registered',
      'weak-password' => 'Please choose a stronger password',
      'invalid-email' => 'That email address looks invalid',
      _ => e.message ?? 'Authentication failed',
    };
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// The reactive profile of the current user (null when signed out).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchProfile();
});
