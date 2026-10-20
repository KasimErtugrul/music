/// Veri katmanından yukarı çıkan, eklentiden bağımsız hata kodları.
/// UI bu kodu yerelleştirilmiş mesaja çevirir; ham mesaj yalnızca günlük içindir.
enum AppErrorCode {
  mediaQueryFailed,
}

class AppException implements Exception {
  const AppException(this.code, {this.message, this.cause});

  final AppErrorCode code;
  final String? message;
  final Object? cause;

  @override
  String toString() => 'AppException($code, $message, cause: $cause)';
}
