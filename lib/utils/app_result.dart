class AppResult {
  final bool success;
  final String? message;

  /// The user cancelled before the answer came back — not a failure, so
  /// callers should show nothing.
  final bool cancelled;

  const AppResult(
    this.success,
    this.message, {
    this.cancelled = false,
  });

  bool get isSuccess => success;
}
