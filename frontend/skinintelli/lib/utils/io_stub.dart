/// Stub classes for `dart:io` to allow compilation on Flutter Web.
///
/// On web platforms, `dart:io` is not available. These stubs provide
/// placeholder classes that match the `dart:io` API but are only used
/// in non-web catch clauses.

class SocketException implements Exception {
  final String message;
  SocketException(this.message);

  @override
  String toString() => 'SocketException: $message';
}

class HandshakeException implements Exception {
  final String message;
  HandshakeException(this.message);

  @override
  String toString() => 'HandshakeException: $message';
}
