import 'dart:async';

/// Kullanıcı yazarken her tuş vuruşunda arama yapmayı engeller.
class Debouncer {
  Debouncer({this.milliseconds = 300});

  final int milliseconds;
  Timer? _timer;

  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) _timer!.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();