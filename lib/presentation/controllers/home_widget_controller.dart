import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/data/datasources/home_widget_datasource.dart';
import 'package:resonance/data/repositories/home_widget_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeWidgetController extends GetxController {
  final HomeWidgetRepository _repo;
  final HomeWidgetDatasource _datasource;
  final PlayerController _player;
  final LibraryRepository _libraryRepo;
  final SharedPreferences _prefs;

  HomeWidgetController(
    this._repo,
    this._datasource,
    this._player,
    this._libraryRepo,
    this._prefs,
  );

  StreamSubscription? _stateSub;
  StreamSubscription? _songSub;

  @override
  void onInit() {
    super.onInit();
    _listenToPlayer();
  }

  void _listenToPlayer() {
    // Şarkı değiştiğinde kapak da değişir → artwork'u yeniden kaydet
    _songSub = _player.currentItem.listen((item) {
      if (item != null) _updateWidget(updateArtwork: true);
    });

    // Sadece play/pause → artwork değişmez, sadece veriyi güncelle
    _stateSub = _player.isPlaying.listen((_) {
      _updateWidget(updateArtwork: false);
    });
  }

  Future<void> _updateWidget({required bool updateArtwork}) async {
    try {
      final song = _player.currentSong;
      final isTransparent = _prefs.getBool('widget_transparent') ?? false;

      if (updateArtwork) {
        final bytes =
            song == null ? null : await _libraryRepo.artwork(song.id, size: 200);
        await _datasource.saveArtwork(bytes);
      }

      await _repo.updateWidget(
        title: song?.title ?? '',
        artist: song?.artist ?? '',
        isPlaying: _player.isPlaying.value,
        isTransparent: isTransparent,
      );
    } catch (e, st) {
      debugPrint('Widget güncelleme hatası: $e\n$st');
    }
  }

  Future<void> setTransparency(bool value) async {
    await _prefs.setBool('widget_transparent', value);
    await _updateWidget(updateArtwork: false);
  }

  @override
  void onClose() {
    _stateSub?.cancel();
    _songSub?.cancel();
    super.onClose();
  }
}