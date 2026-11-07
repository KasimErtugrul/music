import 'dart:async';

/// FAZ 2 (K1): ses tek sahipliği.
///
/// Uygulamada ses (volume) bugüne kadar dört bağımsız mantık tarafından
/// yazılıyordu — oynat/duraklat rampası, kullanıcı sesi, odak duck'ı ve
/// uyku zamanlayıcısı. Birbirlerini eziyorlardı: kullanıcı sesi aktif
/// rampayı iptal ediyor, duck bayat bir değeri geri yüklüyor, uyku
/// zamanlayıcısı kullanıcının tercihini 1.0'a zorluyordu.
///
/// Bu sınıf sesin TEK SAHİBİDİR: ses dört bağımsız katmanın çarpımıdır ve
/// motora yalnızca buradan yazılır. Her katman kendi değerini günceller;
/// koordinatör çarpımı hesaplayıp tek bir yazımla bildirir. Katmanlar
/// birbirini İPTAL ETMEZ — örneğin uyku sönümü sürerken başlayan bir
/// oynatma rampası sönümle çarpılır.
///
/// Katmanlar (hepsi 0.0–1.0 aralığında, sınır değerler dahil):
///  - [setUserVolume]     : kullanıcının ses kaydırıcısı.
///  - [setRampFactor]     : oynat/duraklat yumuşatma rampası çarpanı.
///  - [setDuckFactor]     : ses odağı geçici düşürme (duck) çarpanı.
///  - [setSleepDamping]   : uyku zamanlayıcısı sönümleme çarpanı.
class VolumeCoordinator {
  VolumeCoordinator({required this._writeVolume});

  /// Motora (yalnızca tek noktadan) ses yazan işlev.
  final Future<void> Function(double volume) _writeVolume;

  double _userVolume = 1.0;
  double _rampFactor = 1.0;
  double _duckFactor = 1.0;
  double _sleepDamping = 1.0;

  static double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

  /// Motora yazılan efektif ses: katmanların çarpımı.
  double get effective =>
      _clamp01(_userVolume * _rampFactor * _duckFactor * _sleepDamping);

  /// Kullanıcının son bilinen ses tercihi (rampa/duck/sönümden etkilenmez).
  double get userVolume => _userVolume;

  /// Aktif rampanın son yazılan çarpanı; fade-out'un kaldığı yerden
  /// başlaması için depo tarafından okunur.
  double get rampFactor => _rampFactor;

  Future<void> _apply() => _writeVolume(effective);

  /// Kullanıcı ses kaydırıcısını günceller. Aktif bir rampayı İPTAL ETMEZ;
  /// iptal kararı (eski sözleşme: kullanıcı fade sırasında sesi değiştirirse
  /// rampa düşer) depo katmanında [userTakesOver] ile verilir.
  Future<void> setUserVolume(double v) {
    _userVolume = _clamp01(v);
    return _apply();
  }

  /// Kullanıcı sesi rampayı devralır: rampa çarpanı biter (1.0) ve
  /// kullanıcının değeri TEK yazımla uygulanır. Böylece ortasında kalmış
  /// bir rampa çarpanı kullanıcının istediği sesi söndürmez.
  Future<void> userTakesOver(double v) {
    _userVolume = _clamp01(v);
    _rampFactor = 1.0;
    return _apply();
  }

  /// Rampa tık'ları çarpanı taşır (0.0→1.0 fade-in, x→0.0 fade-out).
  Future<void> setRampFactor(double f) {
    _rampFactor = _clamp01(f);
    return _apply();
  }

  /// Rampayı bitirir: çarpan 1.0'a sabitlenir ve efektif ses tek yazımla
  /// geri gelir (stop sonrası temizlik gibi).
  Future<void> endRamp() {
    _rampFactor = 1.0;
    return _apply();
  }

  /// Ses odağı duck'ı: kesinti başlarken 0.3 gibi bir çarpan, bitince 1.0.
  /// Eski «mevcut sesi sakla / geri yükle» modelinin yerine geçer; bayat
  /// değer geri yüklemesi (kullanıcının ara değişikliğini ezmesi) artık
  /// yapısal olarak imkânsızdır.
  Future<void> setDuckFactor(double f) {
    _duckFactor = _clamp01(f);
    return _apply();
  }

  /// Uyku zamanlayıcısı sönümü: pencere içinde kalan süre oranıyla 1.0→0.0.
  /// Kullanıcı sesini EZMEZ — çarpıma girer (kullanıcı sesi × uyku sönümü).
  Future<void> setSleepDamping(double f) {
    _sleepDamping = _clamp01(f);
    return _apply();
  }
}
