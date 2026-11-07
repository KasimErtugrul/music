import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/external_intent_repository.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class ExternalOpenController extends GetxController {
  final ExternalIntentRepository _repo;
  final PlayerController _player;

  /// Bulgu 3: izin/onboarding kapısının tek kaynağı. Null ise (bazı
  /// testler) kapı yalnız rota denetimiyle çalışır.
  final PermissionController? permission;

  /// Test kapıları: [initialDelay] eski 1500 ms bekleme, [currentRoute]/
  /// [navigate] GetX yönlendirmesinin yerini tutar (PermissionController'ın
  /// aynı isimli enjeksiyon deseni). Üretimde varsayılanlar devrede.
  ExternalOpenController(
    this._repo,
    this._player, {
    this.permission,
    this.initialDelay = const Duration(milliseconds: 1500),
    this.playDelay = const Duration(milliseconds: 600),
    String Function()? currentRoute,
    void Function(String route)? navigate,
  })  : _currentRoute = currentRoute ?? (() => Get.currentRoute),
        _navigate = navigate ?? ((route) => Get.offAllNamed<void>(route));

  final Duration initialDelay;
  final Duration playDelay;
  final String Function() _currentRoute;
  final void Function(String route) _navigate;

  /// İzni/onboarding'i beklerken saklanan niyet. Kapı tamamlandığında
  /// oynatılır (kullanıcıya görünen tek kanal: oynatıcının kendisi).
  final pendingUri = Rxn<String>();
  Worker? _mediaWorker;
  bool _hasHandledInitial = false;

  /// Kapının kapalı olduğu rotalar: açılış akışı bu ekranların ÜSTÜNE
  /// basmamalı (Bulgu 3: offAllNamed izin akışını eziyordu). Boş değer
  /// rota henüz kurulmamış demektir — temkinli davranıp kapıyı kapalı
  /// sayarız.
  static const Set<String> _gateRoutes = <String>{
    AppRoutes.splash,
    AppRoutes.permission,
    AppRoutes.onboarding,
    '',
  };

  @override
  void onInit() {
    super.onInit();
    // Bulgu 3: izin verilince bekleyen niyet oynatılır (kapı "tamamlandı"
    // anı: PermissionController.media granted'e döner — onboarding sayfa 3
    // ve izin sayfası dahil tüm kapı yolları bu Rx'i besler).
    final perm = permission;
    if (perm != null) {
      _mediaWorker = ever<AppPermissionStatus>(perm.media, (status) {
        if (status.isGranted) _resumePending();
      });
    }
    _listen();
    _handleInitial();
  }

  @override
  void onClose() {
    _mediaWorker?.dispose();
    super.onClose();
  }

  Future<void> _handleInitial() async {
    if (_hasHandledInitial) return;
    _hasHandledInitial = true;

    // Splash + permission + home akışının tamamlanmasını bekle
    await Future<void>.delayed(initialDelay);

    final uri = await _repo.getInitialUri();
    if (uri != null && uri.isNotEmpty) {
      _schedulePlay(uri);
    }
  }

  void _listen() {
    _repo.listenForNewIntents((uri) {
      if (uri.isNotEmpty) _schedulePlay(uri);
    });
  }

  /// Bulgu 3: kapı denetimi (İLK VARILIŞ). İzin yoksa veya açılış akışı
  /// (splash/permission/onboarding) hâlâ ekrandaysa niyet OYNATILMAZ;
  /// pendingUri olarak saklanır. Resume yolunda bu denetim TEKRARLANMAZ —
  /// tetiğin kendisi (media granted) «kapı tamamlandı» sinyalidir ve izin
  /// akışı bu anda home'a dönüyor; rota yeniden okunursa yarış her seferinde
  /// kapıyı yeniden kapatır ve niyet sonsuza dek bekler.
  bool _gateOpen() {
    if (_gateRoutes.contains(_currentRoute())) return false;
    final perm = permission ??
        (Get.isRegistered<PermissionController>()
            ? Get.find<PermissionController>()
            : null);
    if (perm != null && !perm.media.value.isGranted) return false;
    return true;
  }

  /// Adresin son parçasından (uzantısız) başlık üretir; anlamlı değilse genel ad.
  String _titleFromUri(String uri) {
    final segs = Uri.tryParse(uri)?.pathSegments ?? const <String>[];
    final last = segs.isEmpty ? '' : segs.last;
    final dot = last.lastIndexOf('.');
    final base = dot > 0 ? last.substring(0, dot) : last;
    return (base.isEmpty || int.tryParse(base) != null) ? 'Harici dosya' : base;
  }

  /// Kapı açıksa splash / home navigasyonunun tamamlanmasını bekleyip
  /// oynatıcı sayfasına geç. `offAllNamed` ile tekrar/çakışma riski yok.
  /// Kapı kapalıysa niyet saklanır, oynatma YAPILMAZ.
  void _schedulePlay(String uri) async {
    if (!_gateOpen()) {
      // Bulgu 3: izin akışı atlanmasın; URI kapı tamamlanınca oynatılır.
      pendingUri.value = uri;
      return;
    }
    pendingUri.value = null;
    await _playNow(uri);
  }

  /// Bulgu 3: kapı tamamlandı (media granted) tetiği. Rota denetimi
  /// TEKRARLANMAZ (yukarıdaki not); bekleyen niyet tüketilip oynatılır.
  void _resumePending() {
    final uri = pendingUri.value;
    if (uri == null || uri.isEmpty) return;
    pendingUri.value = null;
    _playNow(uri);
  }

  Future<void> _playNow(String uri) async {
    try {
      // Navigator'ın hazır olduğundan emin ol
      await Future<void>.delayed(playDelay);

      // Harici dosya kütüphanede yok → geçici SongModel.
      // ID'yi negatif yapıyoruz; MediaStore ID'leri (pozitif) ile çakışmaz.
      final tempSong = SongModel(
        id: -(uri.hashCode.abs() + 1),
        uri: uri,
        path: '',
        title: _titleFromUri(uri),
        durationMs: 0,
        sizeBytes: 0,
      );

      await _player.playSong(tempSong);

      // Harici dosyanın özel oynatma ekranına geç (geçici SongModel
      // argüman olarak taşınır; kütüphane kimliği olmadığı için favori/
      // etiket akışları bu sayfada sunulmaz).
      if (_currentRoute() != AppRoutes.externalPlayer) {
        _navigate(AppRoutes.externalPlayer);
      }
    } catch (e, st) {
      debugPrint('Harici dosya açılamadı: $e\n$st');
      Get.snackbar(
        'Hata',
        'Harici dosya açılamadı. Bu dosya için izin verilmemiş olabilir.\n$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
