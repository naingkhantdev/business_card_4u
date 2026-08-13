import '../exception/custom_exception.dart';

/// Converts anything thrown by the data layer into a sentence that is safe to
/// put in front of a user.
///
/// [CustomException] already carries a friendly message built by
/// `BcaDataAgentImpl._messageFromDioError`, so it is passed through. Anything
/// else is a bug rather than a handled condition, so it collapses to
/// [fallback] instead of leaking a Dart type name or a stack trace into a
/// toast.
String friendlyErrorMessage(
  Object error, [
  String fallback = 'Something went wrong. Please try again.',
]) {
  if (error is CustomException) {
    final message = error.errorVo.message.trim();
    return message.isEmpty ? fallback : message;
  }

  final raw = error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('CustomException: ', '')
      .trim();

  if (raw.isEmpty || _looksTechnical(raw)) return fallback;
  return raw;
}

/// True when the text is a developer-facing dump rather than a message the
/// user can act on.
bool _looksTechnical(String message) {
  const markers = [
    'DioException',
    'CustomException',
    'SocketException',
    'HandshakeException',
    'FormatException',
    'TypeError',
    'NoSuchMethodError',
    'Stack trace',
    'SQLSTATE',
    'Illuminate\\',
    'statusCode:',
    '#0 ',
    'package:',
    '.dart',
  ];
  return markers.any(message.contains);
}
