import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/auth_repository.dart';

/// Drives sign-in / sign-up form submission and exposes an [AsyncValue] the
/// UI can bind to for loading and error states.
class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signInAnonymously() => _run(() => _repo.signInAnonymously());

  Future<void> signIn(String email, String password) =>
      _run(() => _repo.signInWithEmail(email, password));

  Future<void> register(String email, String password, String name) =>
      _run(() => _repo.registerWithEmail(email, password, name));

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<void> _run(Future<Result<Object?>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = result.when(
      success: (_) => const AsyncData<void>(null),
      failure: (f) => AsyncError<void>(f, StackTrace.current),
    );
  }
}

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
