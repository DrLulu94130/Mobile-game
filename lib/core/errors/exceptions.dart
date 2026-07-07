/// Low-level exceptions thrown inside the data layer. These are caught by
/// repositories and mapped to [Failure]s.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => 'AppException: $message';
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']);
}
