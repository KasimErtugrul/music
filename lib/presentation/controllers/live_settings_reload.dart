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
/// PlaylistController `PlaylistBinding` içinde `lazyPut(fenix)` ile
/// kayıtlıdır ve `loadPlaylists()`'i yalnız onInit'te bir kez çalıştırır;
/// canlıyken içe aktarma sonrası listesi bayat kalırdı. Burada yalnız
/// CANLI örneği tazeleriz: `isRegistered` fabrika KAYDINI, `isPrepared`
/// ise henüz hiç kurulmamış fabrikayı işaretler (GetX 4.7: lazyPut +
/// isInit=false). Hiç açılmamışsa (kullanıcı bu oturumda çalma
/// listeleri sayfasına girmediyse) örnek ÖRNEKLENDİRİLMEZ; sayfa ilk
/// açıldığında onInit zaten taze veri yükler. Hata akışı başarısız
/// saymaz (yukarıdaki zincirle aynı sözleşme).
Future<void> reloadLivePlaylistControllers() async {
  if (!Get.isRegistered<PlaylistController>()) return;
  // isPrepared = lazyPut fabrikası kurulu ama örneklendirilmemiş:
  if (Get.isPrepared<PlaylistController>()) return;
  try {
    await Get.find<PlaylistController>().loadPlaylists();
  } on Object catch (e) {
    debugPrint('Reload başarısız (PlaylistController): $e');
  }
}