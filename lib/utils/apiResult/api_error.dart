class ApiError implements Exception {
  // Implement Exception for better error handling
  final int?
  statusCode; // statusCode can be any type in JS, so use int? in Dart
  final String message;
  final List<dynamic>
  errors; // errors is never[] in TS, so use List<dynamic> in Dart
  final StackTrace? stackTrace; // Use StackTrace type for stack information

  ApiError({
    this.statusCode,
    this.message = "Something went wrong",
    this.errors = const [], // Provide a default empty list
    this.stackTrace,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      statusCode: json['statusCode'] as int?,
      message:
          json['message'] as String? ??
          "Something went wrong", // Provide a default
      errors: json['errors'] as List<dynamic>? ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'message': message,
    'errors': errors,
  };

  @override
  String toString() {
    return "ApiError: $message (Status Code: $statusCode)";
  }
}
