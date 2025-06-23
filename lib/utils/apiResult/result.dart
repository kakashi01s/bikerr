class Result<T> {
  final T? data;
  final String? errorMessage;

  Result.success(this.data) : errorMessage = null;
  Result.failure(this.errorMessage) : data = null;

  bool get isSuccess => data != null;
  bool get isFailure => errorMessage != null;
}
