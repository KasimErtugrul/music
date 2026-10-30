import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/data/datasources/home_widget_datasource.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/repositories/home_widget_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oynatıcı durumunu ana ekran widget'ına yansıtır.
///
/// Tasarım kararları:
/// * Başlık/sanatçı `currentSong` yerine `currentItem` (MediaItem) üzerinden okunur.
///   `ResonanceAudioHandler.loadTracks` MediaItem'ı, just_audio kuyruğu yüklenmeden ÖNCE
///   yayınlar; o anda `currentSong` (just_audio indeksine bağlı) eski/null şarkıyı döndürür.
/// * Güncellemeler tek bir döngüde birleştirilir (coalescing). Böylece kapak çekilirken
///   gelen yeni olaylar eski sonucu üzerine yazamaz; her turda EN GÜNCEL durum okunur.
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

  StreamSubscription<dynamic>? _itemSub;
  StreamSubscription<dynamic>? _playingSub;

  bool _running = false;
  bool _dirty = false;

  /// Kapağı en son hangi parça için yazdık. `null` = henüz hiç yazılmadı.
  /// Boş string = "şarkı yok" durumu için kapak temizlendi.
  String? _syncedArtworkFor;

  @override
  void onInit() {
    super.onInit();
    _itemSub = _player.currentItem.listen((_) => _requestSync());
    _playingSub = _player.isPlaying.listen((_) => _requestSync());
    // Açılışta mevcut durumu bir kez yaz: işlem öldürülmüşse widget'ta kalan eski
    // "çalıyor" bilgisi böylece düzelir.
    _requestSync();
  }

  Future<void> _requestSync() async {
    _dirty = true;
    if (_running) return; // çalışan döngü bir sonraki turda yeni durumu okuyacak
    _running = true;
    try {
      while (_dirty) {
        _dirty = false;
        await _sync();
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _sync() async {
    try {
      final item = _player.currentItem.value;
      final itemId = item?.id ?? '';

      if (_syncedArtworkFor != itemId) {
        Uint8List? bytes;
        final songId = item == null ? null : _songIdFromUri(item.id);
        if (songId != null && songId >= 0) {
          bytes = await _libraryRepo.artwork(songId, size: 200);
        }
        // Kapak beklenirken şarkı değiştiyse bu sonucu yazma; döngü yeniden çalışacak.
        if ((_player.currentItem.value?.id ?? '') != itemId) return;
        await _datasource.saveArtwork(bytes);
        _syncedArtworkFor = itemId;
      }

      final current = _player.currentItem.value;
      await _repo.updateWidget(
        title: current?.title ?? '',
        artist: current?.artist ?? '',
        isPlaying: current != null && _player.isPlaying.value,
        isTransparent: _prefs.getBool(SettingsPersistence.widgetTransparent) ?? false,
      );
    } catch (e, st) {
      debugPrint('Widget güncelleme hatası: $e\n$st');
    }
  }

  /// `content://media/external/audio/media/123` -> 123. main.dart içindeki bildirim kapağı
  /// çözücüsüyle aynı kural. Harici (file://) dosyalarda null döner.
  int? _songIdFromUri(String uri) => int.tryParse(uri.split('/').last);

  Future<void> setTransparency(bool value) async {
    await _prefs.setBool(SettingsPersistence.widgetTransparent, value);
    await _requestSync();
  }

  /// Gün 1: yedek içe aktarma sonrası widget'ı güncel tercihlerle yeniden
  /// yazar. [_sync] şeffaflık tercihini her turda taze okuduğu için tek
  /// senkron turu yeterlidir.
  Future<void> reload() => _requestSync();

  @override
  void onClose() {
    _itemSub?.cancel();
    _playingSub?.cancel();
    super.onClose();
  }
}