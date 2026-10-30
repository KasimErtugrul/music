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
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
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