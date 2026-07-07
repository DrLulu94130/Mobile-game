/// Domain-level failures surfaced to the presentation layer.
///
/// Repositories translate low-level [Exception]s (network, Firebase, parsing)
/// into one of these so the UI can show friendly, localisable messages.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Upload failed']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
