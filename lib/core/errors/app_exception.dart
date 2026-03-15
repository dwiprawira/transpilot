enum AppExceptionType {
  invalidCredentials,
  timeout,
  unreachableHost,
  badCertificate,
  malformedEndpoint,
  duplicateTorrent,
  cancelled,
  server,
  network,
  notConfigured,
  unknown,
}

class AppException implements Exception {
  const AppException(
    this.message, {
    this.type = AppExceptionType.unknown,
    this.details,
  });

  final String message;
  final AppExceptionType type;
  final Object? details;

  @override
  String toString() => 'AppException(type: $type, message: $message)';
}
