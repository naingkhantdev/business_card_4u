class AppResult {
  final bool success;
  final String? message;

  const AppResult(
    this.success,
    this.message,
  );

  bool get isSuccess => success;
}
