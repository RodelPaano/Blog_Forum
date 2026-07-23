/// Sealed, typed exceptions for clear error handling.
/// We never leak raw Supabase errors to the UI layer.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '[$code] $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class RateLimitException extends AppException {
  const RateLimitException(super.message, {super.code});
}
