// In lib/utils/exceptions/app_exceptions.dart

// Base Exception class (Assuming you have one)
class AppException implements Exception {
  final String? message;
  final String? prefix;

  AppException([this.message, this.prefix]);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
    : super(message, 'Error During communicating with the server');
}

class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message, 'Invalid request');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String? message])
    : super(message, 'Unauthorized request');
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, 'Invalid input');
}

class NoInternetException extends AppException {
  NoInternetException([String? message])
    : super(message, 'No Internet Connection');
}

class RequestTimeoutException extends AppException {
  RequestTimeoutException([String? message])
    : super(message, 'Request Timeout');
}

// --- ADD THIS NEW EXCEPTION ---
class AuthenticationFailedException extends AppException {
  AuthenticationFailedException([
    String? message = 'Session expired. Please login again.',
  ]) : super(message, 'Authentication Failed: ');
}
// -------------------------------