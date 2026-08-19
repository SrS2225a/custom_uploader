class FtpException implements Exception {
  final String message;

  FtpException(this.message);

  @override
  String toString() {
    return 'FtpException: $message';
  }
}
