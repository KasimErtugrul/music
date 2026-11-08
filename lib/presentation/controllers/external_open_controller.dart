import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/external_intent_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class ExternalOpenController extends GetxController {
  final ExternalIntentRepository _repo;
  final PlayerController _player;
  ExternalOpenController(this._repo, this._player);

  final pendingUri = Rxn<String>();
  bool _hasHandledInitial = false;

  @override
  void onInit() {
    super.onInit();
    _listen();
    _handleInitial();
  }

  Future<void> _handleInitial() async {
    if (_hasHandledInitial) return;
    _hasHandledInitial = true;

    // Splash + permission + home akışının tamamlanmasını bekle
    await Future.delayed(const Duration(milliseconds: 1500));

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

  /// Adresin son parçasından (uzantısız) başlık üretir; anlamlı değilse genel ad.
  String _titleFromUri(String uri) {
    final segs = Uri.tryParse(uri)?.pathSegments ?? const <String>[];
    final last = segs.isEmpty ? '' : segs.last;
    final dot = last.lastIndexOf('.');
    final base = dot > 0 ? last.substring(0, dot) : last;
    return (base.isEmpty || int.tryParse(base) != null) ? 'Harici dosya' : base;
  }

  /// Splash / home navigasyonunun tamamlanmasını bekleyip
  /// oynatıcı sayfasına geç. `offAllNamed` ile tekrar/çakışma riski yok.
  void _schedulePlay(String uri) async {
    try {
      // Navigator'ın hazır olduğundan emin ol
      await Future.delayed(const Duration(milliseconds: 600));

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
      if (Get.currentRoute != AppRoutes.externalPlayer) {
        Get.offAllNamed(AppRoutes.externalPlayer, arguments: tempSong);
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