// Gün 7: yedek içe aktarma ve otomatik yedek geri yükleme sonrasında ayar
// taşıyan canlı controller'ların yeniden yüklenmesi — TEK paylaşılan zincir.
//
// Tarihçe: Gün 1'de bu zincir BackupController'a özel bir yöntemdi ve yalnız
// 5 controller kapsıyordu. Gün 6'da AppSearchController ve AutoBackupController
// reload() kazandı; Gün 6 raporu, manuel içe aktarma zincirinin bu ikisini
// kapsamadığını kayıt altına aldı. Gün 7 denetimi aynı boşluğun daha geniş
// hâlini buldu: AutoBackupController.restore() (otomatik yedek geri yükleme)
// ayarları diske uyguluyor ama hiçbir canlı controller'ı tazelemiyordu.
// İki çağrı noktasının aynı listeyi kopyalamaması için zincir tek paylaşılan
// fonksiyona çıkarıldı (tek doğruluk kaynağı ilkesi, Gün 1).
//
// Sıra önemlidir: EqualizerController.reload() içinden PreferencesController
// okunur; o yüzden tercihler ÖNCE tazelenir. AppSearchController ve
// AutoBackupController yalnız okur; zincirin sonuna eklendiler (Gün 7).
// Kayıtlı olmayan controller (ör. ilgili akış hiç başlamadıysa) sessizce
// atlanır; tek bir reload hatası içe aktarma/geri yükleme akışını
// başarısız saymaz (Gün 1'deki davranışın aynısı).
//
// Gün 9: bu dosyaya ayar zincirinden AYRI ikinci bir tazeleme eklendi —
// reloadLivePlaylistControllers. İçe aktarma/geri yükleme yalnız ayarları
// değil, veritabanındaki çalma listeleri tablosunu da silip yeniden kurar
// (BackupDatasource.importData). Çalma listeleri SettingsPersistence
// .backupKeys kapsamında bir AYAR DEĞİLDİR (BackupModel'in ayrı veri
// alanıdır); bu yüzden Gün 1 doktrini gereği ayar zincirine eklenmedi.
// Ayrıntılar aşağıdaki belgede.
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

/// Yedekten dönen ayarları canlı controller'lara yansıtır. Manuel içe
/// aktarma (BackupController.importData, Gün 1) ve otomatik yedek geri
/// yükleme (AutoBackupController.restore, Gün 7) aynı zinciri kullanır:
/// kullanıcı uygulama yeniden başlatmadan güncel tercihler görür.
Future<void> reloadLiveSettingsControllers() async {
  // Gün 1 sırası (Preferences önce — Equalizer onu okur):
  await _reloadIfRegistered<PreferencesController>();
  await _reloadIfRegistered<ThemeController>();
  await _reloadIfRegistered<SettingsController>();
  await _reloadIfRegistered<EqualizerController>();
  await _reloadIfRegistered<HomeWidgetController>();
  // Gün 7: yalnız okuyan iki controller (Gün 6'da reload() kazanmıştı).
  await _reloadIfRegistered<AppSearchController>();
  await _reloadIfRegistered<AutoBackupController>();
}

Future<void> _reloadIfRegistered<T extends GetxController>() async {
  if (!Get.isRegistered<T>()) return;
  try {
    await (Get.find<T>() as dynamic).reload();
  } on Object catch (e) {
    debugPrint('Reload başarısız ($T): $e');
  }
}

/// Gün 9: içe aktarma/geri yükleme sonrasında canlı çalma listesi
/// durumunun tazelenmesi (Gün 7 raporundaki kayıtlı boşluğun çalma
/// listesi yarısı; favoriler yarısı kayıt düzeltmesiyle çözümsüzdür —
/// FavoriteController Drift canlı akışıyla beslenir, reload gerekmez).
///
/// Bulgu 7: PlaylistController InitialBinding'de `put+permanent` ile
/// kayıtlıdır (eski PlaylistBinding → lazyPut+fenix düzeni silindi) ve
/// `loadPlaylists()`'i onInit'te çalıştırır; canlıyken içe aktarma
/// sonrası listesi bayat kalırdı. Burada canlı örneği tazeleriz.
/// `isPrepared` koruması lazyPut kayıtları için savunmacı kalır: henüz
/// hiç örneklenmemiş fabrikada örnek OLUŞTURULMAZ; sayfa ilk açıldığında
/// onInit zaten taze veri yükler. Hata akışı başarısız saymaz
/// (yukarıdaki zincirle aynı sözleşme).
///
/// Bulgu 17: kullanıcı playlist DETAY sayfasındaysa yalnız liste
/// tazelemesi yetmez — currentPlaylist/currentSongs bayat kalır (silinmiş
/// listenin şarkıları ekranda kalır). Açık detay varsa
/// loadPlaylistDetail de çalıştırılır: silinen listenin detayı boş
/// geçerli değere düşer, kalan listenin şarkıları DB gerçeğiyle
/// yeniden çözümlenir.
Future<void> reloadLivePlaylistControllers() async {
  if (!Get.isRegistered<PlaylistController>()) return;
  // isPrepared = lazyPut fabrikası kurulu ama örneklendirilmemiş:
  if (Get.isPrepared<PlaylistController>()) return;
  try {
    final ctrl = Get.find<PlaylistController>();
    await ctrl.loadPlaylists();
    // Bulgu 17: açık detayın tazelenmesi. loadPlaylists başarısızsa
    // (hasError sözleşmesi) detaya dokunulmaz — eski içerik ekranda kalır.
    final openId = ctrl.currentPlaylist.value?.id;
    if (openId != null) {
      await ctrl.loadPlaylistDetail(openId);
    }
  } on Object catch (e) {
    debugPrint('Reload başarısız (PlaylistController): $e');
  }
}