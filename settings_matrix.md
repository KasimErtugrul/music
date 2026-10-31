# Ayarlar Matrisi (Gün 14 — kapanış)

Resonance 1.0.0+1 · 1 Kasım 2026

Plandaki Gün 10 maddesi («Tüm ayarlar için kanıt tablosu») ve Gün 14 kapanış
maddesi («settings_matrix.md güncel») bu belgeyle yerine getirilir. Her ayar
için beş kanıt sütunu tutulur: **arayüz** (hangi sayfada, hangi bileşenle
düzenlendiği), **kalıcılık** (gerçek prefs anahtarı veya JSON alanı),
**tüketici** (davranışı gerçekten değiştiren kod), **test** (kanıt test
dosyası) ve **yedek** (yedeğe girip girmediği — `SettingsPersistence.backupKeys`
ile birebir uyumludur; `settings_backup_keys_test.dart` bu uyumu zorlar).

İki katman karıştırılmamalıdır (bkz. `lib/core/settings/settings_persistence.dart`):

- `SettingsPersistence` — diskte gerçekten yazılan prefs anahtarları.
- Kalıcılığı JSON dizgenin İÇİNDE olan ayarlar (playback/library/theme)
  sütunda «`playback_settings` › alanAdı» biçiminde gösterilir.

## 1. Genel (Ayarlar ana sayfası)

| Ayar | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Dil | Ana sayfa · `SettingsChoiceTile` (SegmentedButton: Sistem/Türkçe/English) | `language_code` | `app.dart` locale seçimi (`'system'/'tr'/'en'`) | `test/core/localization_test.dart` | ✓ |
| Ayarlarda arama | Ana sayfa arama çubuğu · `SettingsSearchController` | — (sorgu oturumluk; son aramalar `search_history` Arama sayfasına aittir) | `SettingsSearchController.filter` (TR+EN başlık eşleme) | `settings_two_pane_test.dart` (arama sonucu akışı) | ✓ (`search_history`) |

## 2. Çalma (`playback_settings` JSON — `PlaybackSettingsModel`)

| Ayar | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Sarma süresi | Çalma › Denetim · `SettingsChoiceTile` | `playback_settings` › `seekIntervalSeconds` | `PlayerController.fastForward` / `rewind` | `test/core/playback_library_json_test.dart`; `settings_page_reset_test.dart` | ✓ |
| Uygulama açılınca otomatik devam et | Çalma › Başlangıç davranışı · `SettingsSwitchTile` | `playback_settings` › `autoResume` | açılış kuyruk geri yükleme yolu (PlayerController oturum geri yükleme) | `playback_library_json_test.dart` | ✓ |
| Kulaklık çıkarınca duraklat | Çalma › Denetim · `SettingsSwitchTile` | `playback_settings` › `pauseOnHeadphone` | `audio_session_datasource` (shouldPauseOnUnplug) | `playback_library_json_test.dart` | ✓ |
| Yeni kuyruk başlarken karıştır (Gün 2 Karar) | Çalma › Başlangıç davranışı · `SettingsSwitchTile` | `playback_settings` › `defaultShuffle` | `PlayerController.playSong` (yalnız yeni kuyrukta) | `test/controllers/player_controller_test.dart` | ✓ |
| Yeni kuyruk başlarken tekrar (Gün 2 Karar) | Çalma › Başlangıç davranışı · `SettingsChoiceTile` (kapalı/tümü/tek) | `playback_settings` › `defaultRepeat` | `PlayerController.playSong` + `repeatMode` Rx eşitlemesi | `player_controller_test.dart` | ✓ |
| Hız | `speed_pitch_sheet.dart` kaydırıcı (onChangeEnd'de kalıcı; Gün 3) | `playback_settings` › `speed` | `PlayerController.setSpeed` | `player_controller_test.dart` | ✓ |
| Perde | `speed_pitch_sheet.dart` kaydırıcı | `playback_settings` › `pitch` | `PlayerController.setPitch` | `player_controller_test.dart` | ✓ |
| Sessizliği atla | Çalma › Ses işleme · `SettingsSwitchTile` | `playback_settings` › `skipSilence` | Gün 2 alan dinleyicisi → `setSkipSilenceEnabled` (çalan parçaya anında) | `player_controller_test.dart` + `live_settings_reload_test.dart` | ✓ |
| ReplayGain | Çalma › Ses işleme · `SettingsSwitchTile` | `playback_settings` › `replayGain` | Gün 2 alan dinleyicisi (çalan parçaya anında) | `live_settings_reload_test.dart` | ✓ |

Model notu (Gün 10): `fromJson` alan-seviyesi güvenli ayrışmadır; tek bozuk
alan yalnız o alanı varsayılana döndürür. Planın «ileri/geri atlama süresini
ayır» maddesi için tek `seekIntervalSeconds` alanı korunmuştur (bkz. GUN13
raporu Ek bulgular 3).

## 3. Kitaplık (`library_settings` JSON — `LibrarySettingsModel`)

| Ayar | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Açılışta kütüphaneyi tara | Kitaplık · `SettingsSwitchTile` | `library_settings` › `scanOnStartup` | açılış rescan yolu (LibraryController) | `playback_library_json_test.dart`; `settings_page_reset_test.dart` (Kitaplık sıfırlaması) | ✓ |
| En kısa süre | Kitaplık · `SettingsChoiceTile` (Kapalı/30 sn/60 sn — Gün 5 yerelleştirme) | `library_settings` › `minDurationSeconds` | tarama filtresi (kısa kayıtları at) — `library_repository` indeksleme | `playback_library_json_test.dart` | ✓ |
| Hariç tutulan klasörler | Dışlanan klasörler sayfası (boş durum, kaydırarak sil, Geri Al — Gün 13) | veritabanı listesi (`excluded_folders` tablosu — prefs DEĞİL) | tarama filtresi | `excluded_folders_page_test.dart`; `test/local/app_database_test.dart` | ✓ (listeler yedekte taşınır) |

## 4. Görünüm (`active_theme_settings` JSON — `ThemeSettings`)

Sayfa birleşimi (Gün 13 Karar): Galeri + Gelişmiş tek «Görünüm» sayfasıdır
(`theme_gallery_page.dart`); yazı tipi/ölçek kendi sayfasındadır; oynatıcı ve
liste stili kendi sayfalarındadır. Kayıt defterindeki 4 görünüm girdisi
(themeMode/themeColorSource/themeAmoled/themeHighContrast) birleşik sayfaya
gider (`appearance_page_test.dart` son testi).

| Ayar | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Tema modu | Görünüm · 4 seçenekli `SettingsChoiceTile` (Sistem/Açık/Koyu/AMOLED — Gün 13) | `active_theme_settings` › `themeMode` | `ThemeEngine.light/dark` + `GetMaterialApp.themeMode` | `appearance_page_test.dart`; `test/controllers/theme_controller_test.dart` | ✓ |
| AMOLED | Yukarıdaki mod seçeneği (ayrı anahtar DEĞİL — Gün 13) | `active_theme_settings` › `amoled` | `ThemeEngine.dark` saf siyah yüzeyler | `appearance_page_test.dart` (AMOLED koyu+saf siyah); golden `settings_home_amoled.png` | ✓ |
| Renk kaynağı | Görünüm · `SettingsChoiceTile` (Hazır palet/Kapaktan) | `active_theme_settings` › `themeSource` | `ThemeController` şema kanalları (system=Material You, artwork=kapak türetme) | `theme_controller_test.dart` | ✓ |
| Hazır palet | Görünüm · görsel ızgara (seçili gösterge, Gün 3) | `active_theme_settings` › `seedColor` | `ColorScheme.fromSeed` | `test/core/theme_settings_json_test.dart` | ✓ |
| Zamanlanmış koyu mod | Görünüm · anahtar + saat seçiciler (yalnız açıkken görünür) | `active_theme_settings` › `scheduledDarkEnabled` + 4 saat alanı | `ThemeController._computeThemeMode` (Gün 3 Karar: varsayılan kapalı) | `theme_controller_test.dart` | ✓ |
| Yüksek kontrast | Görünüm · anahtar | `active_theme_settings` › `highContrast` | `ThemeEngine` (dinamik şemaya da uygulanır — Gün 3) | `theme_settings_json_test.dart` + golden `settings_home_high_contrast.png` | ✓ |
| Yüzey tonu | Görünüm › Şekil ve yoğunluk · anahtar | `active_theme_settings` › `surfaceTint` | `ThemeEngine` (Card/Dialog/NavigationBar + Gün 3 etiket düzeltmesi) | `theme_settings_json_test.dart` | ✓ |
| Köşe yuvarlaklığı | Görünüm › Şekil ve yoğunluk · anahtar | `active_theme_settings` › `roundedCorners` | `ThemeEngine` (BottomSheet/SnackBar/PopupMenu dahil — Gün 3) | `theme_settings_json_test.dart` | ✓ |
| Yoğunluk | Görünüm › Şekil ve yoğunluk · `SettingsChoiceTile` | `active_theme_settings` › `density` | `ThemeEngine` visualDensity | `theme_settings_json_test.dart` | ✓ |
| Yazı tipi | Yazı tipi sayfası · `RadioListTile` | `active_theme_settings` › `fontFamily` | `ThemeEngine` textTheme | `theme_settings_json_test.dart` | ✓ |
| Yazı ölçeği | Yazı tipi sayfası · Slider (sürükleme = önizleme, bırakınca kalıcı — Gün 3) | `active_theme_settings` › `textScale` | `app.dart` builder: sistem ölçeğiyle ÇARPILIR, 0.5–2.0'a kırpılır | `theme_settings_json_test.dart` + `settings_overflow_scan_test.dart` (1.3×1.4) | ✓ |
| Oynatıcı arka planı / kapak biçimi / ilerleme çubuğu / mini oynatıcı / animasyon seviyesi | Oynatıcı stili sayfası · `SettingsChoiceTile` × 5 | `active_theme_settings` › `player` (`PlayerThemeExtension`: backgroundStyle, artworkShape, seekBarStyle, miniPlayerStyle, animationLevel) | `player_page`, `mini_player`, `song_tile`, `theme_engine` (animasyon dekorları) | `mini_player_test.dart`; `theme_settings_json_test.dart` | ✓ |
| Liste görünümü | Liste stili sayfası · `SettingsChoiceTile` (Sık/Dinamik/Izgara) | `active_theme_settings` › `listViewMode` | `songs/albums/artists` sayfaları (Responsive ile birleşik davranış) | `theme_settings_json_test.dart` | ✓ |

## 5. Ses (Ekolayzer)

| Ayar | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Ekolayzer açık/kapalı | Ekolayzer sayfası · anahtar | `equalizer_enabled` | ses işleme zinciri (AudioEffect katmanı) | `settings_backup_keys_test.dart` (kapsam kanıtı) | ✓ |
| Bant kazançları | Ekolayzer sayfası · bant kaydırıcıları | `equalizer_gains` (dB listesi JSON) | AudioEffect katmanı | `settings_backup_keys_test.dart` (kapsam kanıtı) | ✓ |
| Loudness | Ekolayzer sayfası | `equalizer_loudness` | AudioEffect katmanı | `settings_backup_keys_test.dart` (kapsam kanıtı) | ✓ |

## 6. Bildirim ve widget

| Ayar | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Widget şeffaf modu | Widget sayfası · Switch + canlı önizleme | `widget_transparent` (Android `MusicWidgetProvider.kt` aynı anahtarı okur) | `HomeWidgetController.setTransparency` → RemoteViews | Gün 13 `settings_page_reset_test.dart` (şeffaflık sıfırlaması); `settings_overflow_scan_test.dart` (çizim) | ✓ |
| Bildirim önizlemesi | Bildirim sayfası (Gün 8 Karar: yalnız yeniden adlandırıldı; sayfada kalıcı ayar yok) | — | — | `settings_overflow_scan_test.dart` (çizim) | — |

## 7. Yedek ve veri

| Öğe | Arayüz | Kalıcılık | Tüketici | Test | Yedek |
|---|---|---|---|---|---|
| Manuel yedek al / geri yükle | Yedekleme sayfası · düğmeler + onay diyaloğu | yedek dosyası (şema sürümlü — Gün 9/10) | `BackupController.exportData/importData` + tüm controller `reload()` (Gün 1) | `test/core/settings_backup_keys_test.dart`; `test/core/settings_key_migration_test.dart` | — (kaynağın kendisi) |
| Otomatik yedekleme | Yedekleme › `AutoBackupSection` (anahtar, sıklık, saklanacak sayı) | `settings_auto_backup_enabled` / `_frequency` / `_keep` | `AutoBackupController` (zamanlama + prune) | `test/controllers/auto_backup_controller_test.dart`; `auto_backup_section_test.dart` | ✓ |
| Son yedek zamanları | Yedekleme sayfası trailing metin | `last_backup_at`, `settings_auto_backup_last` | zaman gösterimi | `settings_backup_keys_test.dart` («yedeklenmez» listesi) | Bilinçli YOK |
| Tüm ayarları sıfırla | Ana sayfa alt kartı · onay diyaloğu (Gün 6) | diskteki tüm `backupKeys` kaldırılır | `PreferencesController.resetAll` + canlı controller reload | `settings_home_reset_test.dart`; `test/core/settings_reset_test.dart` | — |
| Sayfa sıfırlama («Bu sayfayı varsayılana döndür») | Çalma/Kitaplık/Widget/Görünüm AppBar · `SettingsPageResetAction` (Gün 13) | yalnız sayfada yaşayan anahtarlar | `resetPlayback` / `resetLibrary` / widget şeffaflığı / tema alanları | `settings_page_reset_test.dart`; `appearance_page_test.dart` | — |
| Dinleme geçmişi ve istatistik temizleme | Veri temizleme akışı (Gün 9, onaylı) | HistoryDao / istatistik tabloları | HistoryDao / StatsRepository | `test/local` DAO testleri | Bilinçli YOK (geçmiş yedek kapsamında değildir) |
| Yalnız ayarları dışa/içe aktar | Yedekleme sayfası (Gün 9) | `backupKeys` + şema sürümü | `BackupDatasource` | `settings_backup_keys_test.dart` | — |

## 8. Gün 14 ekleri (erişilebilirlik / geniş ekran / kapanış)

| Öğe | Kanıt |
|---|---|
| Taşma taraması (sistem 1.3 × uygulama 1.4 = 1.82) | `test/widgets/settings_overflow_scan_test.dart` — 14 ayar sayfası × TR/EN; bulunan 3 taşma düzeltildi (bildirim medya kartı satırı, uyku kartı eylemleri, yedek bölüm başlığı) |
| İki bölmeli ayarlar (ayalar alanı ≥ 840 dp) | `settings_home_page.dart` (LayoutBuilder + `Responsive`); `test/widgets/settings_two_pane_test.dart` (compact route davranışı korundu) |
| Tema golden testleri | `test/widgets/settings_theme_golden_test.dart` + `test/widgets/goldens/*.png` (açık/koyu/AMOLED/yüksek kontrast; toleranslı piksel karşılaştırıcı) |
| Ayar satırlarında erişilebilirlik | Gün 12 zemininde 48dp dokunma hedefi + Semantics (`settings_tiles_test.dart`); Gün 14'te yeni ölçek testleriyle yeniden doğrulandı |

Bakım kuralı: YENİ BİR AYAR EKLERKEN (1) `SettingsPersistence` + `backupKeys`,
(2) `SettingsRegistry` girdisi, (3) bu tablo — üçü birlikte güncellenmelidir;
ilkini atlamak `settings_backup_keys_test.dart`ı, ikincisini atlamak arama
testlerini kırmalıdır.
