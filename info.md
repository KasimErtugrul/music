Resonance Ayarlar Sistemi: Kod Yazdırma Prompt’u (Gün Gün)
Resonance 1.0.0+1 kaynak kodunun statik okunmasına göre hazırlandı · 30 Ekim 2026
0. Nasıl kullanılır
Bölüm 1’deki Ana Prompt’u kodlama yapay zekâsına bir kez yapıştırın. Sonra her gün için ilgili Gün bölümünü ayrı mesaj olarak verin. Gün bitince raporu (değişen dosyalar, analyze ve test çıktısı) kontrol edin; yeşil olmadan sonraki güne geçmeyin.
Dürüstlük notu: Bulgular kodun okunmasından çıkarıldı. Derleme, test ve cihaz çalıştırması yapılmadı (Flutter ortamı yoktu). Yanında Doğrula yazan maddeleri önce kendiniz yeniden üretin. Okunmayan dosyalar: equalizer_page, audio_handler.dart, auto_backup_*, library_repository iç mantığı, theme_preview_card, custom_theme_editor_page’in tamamı, queue ve search sayfaları.
Verilen kararlar
• Varsayılan karıştırma ve tekrar: yeni kuyruk başlatılırken uygulanır (kullanıcı onayı).
• Zamanlanmış koyu mod: varsayılan kapalı; kayıtlı saatler varsayılandan farklıysa açık sayılır (Gün 3).
• Bildirim sayfası: bu planda yalnız «Bildirim önizlemesi» olarak yeniden adlandırılır (Gün 8).
• Özel tema: yalnız renk ve şekil alanlarını uygular (Gün 3).
• Tema ayarlarındaki «Gelişmiş» sayfa Gün 13’te Görünüm sayfasına birleşir.
İkinci gözden geçirmede kodda yeniden doğrulananlar: PreferencesController.resetAll() hiçbir ekrandan çağrılmıyor; SettingsDefaults.dynamicColor ve amoledDark kullanılmıyor; kütüphane sekmeleri sabit 5 adet; kesinti işleyici audio_session_datasource.dart içinde; otomatik yedekleme anahtarları settings_ önekli olduğu için yedekte zaten var.
1. Ana Prompt (bir kez yapıştırın)
Sen Resonance adlı Flutter müzik çalar projesinde çalışan kıdemli bir Flutter geliştiricisisin. Mimari: GetX (controller + Get.find), Drift (yerel veritabanı), SharedPreferences (ayarlar), audio_service + just_audio + audio_session (oynatma), l10n (lib/l10n/app_tr.arb ve app_en.arb). Kurallar:
1. Önce dosyayı oku, sonra değiştir. Okumadığın dosya hakkında varsayım yapma; emin değilsen «doğrulanamadı» yaz.
2. Her günün sonunda sırayla çalıştır: flutter gen-l10n; dart run build_runner build --delete-conflicting-outputs (yalnızca Drift tablosu değiştiyse); flutter analyze; flutter test. Çıktıyı olduğu gibi yapıştır. Çalıştıramadıysan bunu açıkça yaz, «geçti» deme.
3. Kullanıcıya görünen her metin için app_tr.arb VE app_en.arb’a anahtar ekle. Koda sabit metin yazma.
4. Üretilmiş dosyaları (*.g.dart ve app_localizations*.dart) elle düzenleme. Kaynak dosyalar CRLF satır sonu kullanıyor: düzenlerken satır sonlarını koru ve dosyaları toptan yeniden biçimlendirme (dart format yalnızca dokunduğun dosyalara).
5. Yeni bağımlılık ekleme; gerekirse gerekçesiyle önce sor.
6. Her ayar için üç kanıt ver: (a) arayüzde değişiyor, (b) kalıcı (uygulama yeniden açılınca duruyor), (c) bir tüketicisi var (davranışı gerçekten değiştiriyor). Kanıt: test veya tüketici satırı.
7. Kayıtlı kullanıcı verisini bozma: eski JSON/prefs için geriye dönük uyum koru (eksik alan = eski varsayılan).
8. Günün listesinde olmayan refactor yapma. Fark ettiğin ek sorunları «Ek bulgular» altında listele, düzeltme.
9. Bu planda «Karar:» ile başlayan maddeler verilmiş kararlardır; onlardan sapma. Planda olmayan bir karar noktası çıkarsa seçenekleri ve önerini yaz, onay bekle.
10. Gün sonu rapor formatı: Değişen dosyalar / Yapılanlar / Yapılamayanlar ve neden / Test sonucu / Ek bulgular.
FAZ 1: HATA DÜZELTME (Gün 1–5)
Gün 1: Veri kaybı, yedekleme ve geri yükleme
Bulgular:
• backup_datasource.dart exportData() ayarlardan yalnızca settings_ önekli anahtarları, language_code, active_theme_settings ve equalizer_enabled’ı alıyor. Gerçek anahtarlar playback_settings, library_settings (preferences_repository.dart), widget_transparent, equalizer_gains, equalizer_loudness kapsam dışı. Sonuç: Çalma ve Kitaplık ayarları yedeğe girmiyor.
• importData sonrası canlı controller’lar (PreferencesController, ThemeController, SettingsController, EqualizerController) yeniden okunmuyor; backup_controller.dart yalnızca rescan çağırıyor. İçe aktarılan ayarlar uygulama yeniden başlayana kadar uygulanmıyor. Doğrula.
Görevler:
• Tek bir SettingsPersistence.backupKeys listesi oluştur (settings_keys.dart yanında); backup_datasource bunu kullansın.
• Test: PreferencesController, SettingsController, ThemeController, EqualizerRepository ve widget şeffaflığı setter’larını sahte SharedPreferences ile çağır; prefs.getKeys() içindeki her anahtar backupKeys içinde ya da açıkça «yedeklenmez» listesinde (ör. last_backup_at) olsun. Yeni anahtar eklenip listelenmezse test kırılsın.
• Import: tip güvenli yazım, bilinmeyen anahtarları yok say, beklenmeyen değer tipinde çökme.
• PreferencesController, SettingsController, ThemeController, EqualizerController ve HomeWidgetController için reload() ekle; BackupController.importData sonunda çağır.
Kabul: Yedek al, ayarları değiştir, yedeği içe aktar; yeniden başlatmadan Çalma, Kitaplık, Tema, Dil ve EQ ayarları yedekteki hale dönsün. Testler yeşil.
Gün 2: Canlı uygulanmayan Çalma ayarları
Bulgular (player_controller.dart, preferences_controller.dart):
• skipSilence ve replayGain anahtarları yalnızca kaydediyor. Uygulama anı playSong, oturum geri yükleme ve doğal parça geçişi. Ayar değişimini dinleyen bir ever() benzeri yapı yok; çalarken değiştirilen ayar sonraki parçaya kadar etkisiz. Doğrula (cihazda dinleyerek).
• defaultShuffle ve defaultRepeat yalnızca kayıtlı kuyruk YOKKEN uygulanıyor. Kuyruk ilk çalmadan sonra kaydedildiği için pratikte ayar bir daha devreye girmiyor. Bu yolda shuffleEnabled ve repeatMode Rx değerleri de güncellenmiyor; motor ile arayüz ayrışabilir.
• gapless alanı modelde var ama arayüzde ve tüketicide yok.
Görevler:
• PlayerController içinde prefCtrl.playback için alan bazlı değişim dinleyicisi: skipSilence ve replayGain değişince çalan parçaya anında uygula.
• Karar: defaultShuffle ve defaultRepeat, kullanıcı yeni bir kuyruk başlattığında (playSong) uygulanır; uygulama açılışında kayıtlı kuyruğun durumu korunur. Etiketleri «Yeni kuyruk başlarken karıştır» ve «Yeni kuyruk başlarken tekrar» yap. Doğrula: karıştırma açıkken dokunulan şarkının ilk çalıp çalmadığı (shuffle ile initialIndex davranışı).
• Hangi seçenek seçilirse seçilsin Rx durumlarını motorla eşitle.
• gapless: eski JSON uyumu için okumaya devam et, yorumla «kullanılmıyor» olarak işaretle.
Kabul: Çalarken skip silence ve ReplayGain anında etki eder; varsayılanlar seçilen anlamda çalışır; fake repository ile testler yeşil.
Gün 3: Tema mantık hataları
Bulgular:
• theme_controller.dart _isScheduledTime() ve varsayılan 20:00–07:00 aralığı: tema modu Sistem iken (varsayılan) uygulama, sistem açık olsa bile bu saatlerde koyuya zorlanıyor ve kapatma anahtarı yok.
• app.dart builder TextScaler.linear(scale) kullanıyor: sistem yazı ölçeğini ezer (yorum «çarpılır» diyor, kod çarpmıyor). 1.0 değerinde bile erişilebilirlik ölçeği yok sayılıyor.
• font_settings_page.dart Slider.onChanged her sürükleme adımında setTextScale çağırıyor: her adımda JSON kaydı, Get.changeThemeMode, kaynak «artwork» ise kapak okuma ve palet hesabı, ve app.dart Obx ile kök GetMaterialApp yeniden kurulumu. speed_pitch_sheet.dart’taki hız ve perde kaydırıcıları da aynı kalıpla doğrudan kaydediyor görünüyor (Doğrula).
• theme_settings_page.dart hazır palet seçicisi value: 'default' sabit; seçili palet yansımıyor.
• ThemeSettings.fromJson: bozuk veya bilinmeyen tek alan (ThemeMode.byName, int/double) tüm temayı sessizce sıfırlar (theme_repository try/catch null döner).
• theme_gallery_page.dart: özel tema seçilince setSettings tüm ayarları (yazı tipi, ölçek, oynatıcı stili, liste modu) ezer; özel temalarda seçili göstergesi yok; «+» düğmesinin tooltip’i commonSave.
Ek bulgular (Doğrula): theme_engine.dart’ta highContrast yalnızca fromSeed’e contrastLevel veriyor; ardından primary ve primaryContainer seed’den yeniden hesaplandığı için etkisi kısmi, dinamik (sistem/kapak) şemada hiç uygulanmıyor. surfaceTint ve roundedCorners yalnızca Card, Dialog ve NavigationBar temasına işliyor; BottomSheet, SnackBar, buton ve şarkı satırı köşeleri sabit, oysa ayar adları genel görünüyor. Özel tema dışa aktarma metin paylaşıyor, içe aktarma ise .json dosyası seçtiriyor; ikisi birbirini tamamlamıyor.
Görevler:
• scheduledDarkEnabled alanı ve arayüzde anahtar; saat seçiciler yalnızca açıkken görünsün. Karar: varsayılan kapalı. Geçiş: kayıtlı JSON’da alan yoksa ve saatler 20:00 / 07:00’den farklıysa (kullanıcı bilerek ayarlamıştır) açık say, aksi halde kapalı. Sürüm notuna yaz.
• textScale: sistem ölçeğiyle çarp, toplamı 0.5–2.0 aralığına sıkıştır.
• Slider: sürüklerken yerel önizleme, onChangeEnd’de kalıcıla.
• ThemeController._update: önceki ve yeni ayarı karşılaştır; kapak teması yalnızca kaynak, seed veya mod değişince; Get.changeThemeMode yalnızca mod değişince.
• fromJson: alan bazlı güvenli okuma; ThemeMode.values.asNameMap()[x] ?? system; (num).toDouble().
• Palet seçici: mevcut seed’e eşleşen preset seçili görünsün, eşleşme yoksa «Özel».
• Karar: özel tema yalnız renk ve şekil alanlarını uygular (seed, amoled, highContrast, surfaceTint, roundedCorners, density); font, ölçek, oynatıcı ve liste ayarları kullanıcıda kalır. İçe aktarılan tema da aynı kuralla uygulanır.
• Özel temalarda seçili göstergesi; «+» için yeni l10n tooltip anahtarı.
Ek görevler: highContrast açıkken dinamik şemaya da kontrast uygula ve primary’yi şemadan türet. roundedCorners için BottomSheet, SnackBar ve PopupMenu şekil temalarını ekle; surfaceTint etiketini gerçek etkisini anlatacak biçimde düzelt. Özel tema dışa aktarmayı .json dosyası olarak paylaş (yeni bağımlılık gerekmeden; path_provider ve share_plus mevcut), içe aktarma onu okusun.
Kabul: JSON gidiş-dönüş ve bozuk JSON testi; textScale çarpımı widget testi (sistem 1.3 × uygulama 1.0 = 1.3); zamanlama açık/kapalı testi.
Gün 4: Ayar arama ve kayıt defteri
Bulgular:
• settings_registry.dart eksik: Bildirimler sayfası, Ekolayzer, zamanlanmış koyu mod, yüzey tonu, köşe yuvarlaklığı, yoğunluk, renk kaynağı ve palet, oynatıcı arka planı, kapak şekli, seek bar, mini oynatıcı, otomatik yedekleme, kapak önbelleğini temizleme. Arama bunları bulamaz.
• Dil girdisi arama sonucunda tıklanamaz (pageBuilder null olduğu için onTap null).
• Eşleşme yokken boş ekran; boş durum mesajı yok.
• SettingsSearchController build içinde Get.put ile kuruluyor; sayfa yeniden açıldığında TextField boş ama sorgu controller’da kalmış olabilir. Doğrula.
• settings_keys.dart: yalnızca language_code gerçek prefs anahtarı; diğerleri yalnızca kayıt defteri kimliği (gerçek kalıcılık playback_settings ve library_settings JSON’u). Widget kimliği widget_transparency, gerçek anahtar widget_transparent. settings_defaults.dart’taki dynamicColor ve amoledDark için kod tabanında kullanım yok (arama yapıldı); sil.
Görevler:
• SettingsEntry’ye category, keywords (TR ve EN eş anlamlılar) ve onActivate ekle; eksik tüm ayarları kaydet.
• Dil girdisi için sonuçtan etkinleştirme (seçim diyaloğu).
• Boş sonuç durumu (l10n).
• Arama controller’ını sayfa yaşam döngüsüne bağla; sayfadan çıkınca sorguyu temizle.
• SettingsKeys’i ikiye ayır: gerçek prefs anahtarları ve kayıt defteri kimlikleri; widget anahtarını eşitle.
Kabul: «koyu», «dark», «köşe», «ekolayzer», «bildirim» aramaları doğru sayfaya götürür; test: her girdinin TR ve EN başlığı dolu ve bir etkinleştirme yolu var.
Gün 5: Yerelleştirme, küçük hatalar, testler
Bulgular:
• Sabit metinler: theme_settings_page.dart (Scheduled dark mode, Color source, System (Material You), From artwork, Custom seed, '—' başlıkları); player_style_page.dart (Background, Artwork shape, Mini player, Wide, Compact, '—'); library_settings_page.dart ('Yok / None', '$v s'); custom_theme_editor_page.dart (Seed Color, AMOLED Dark, High Contrast).
• ThemeSettingsPage AppBar başlığı tabSettings (Ayarlar); sayfanın adını yansıtmıyor.
• about_page.dart sürüm '1.0.0' sabit.
• excluded_folders_page.dart: klasör silme onaysız; her ekleme ve silme tam rescan tetikliyor, ilerleme göstergesi yok.
• Ayar katmanına ait test dosyası yok (test/ altında PreferencesController, SettingsRegistry, SettingsSearchController, ThemeController için test görmedim).
Görevler:
• Tüm sabit metinleri l10n’a taşı (TR ve EN); '—' başlıklarını kaldır veya gerçek başlık ver; AppBar başlıklarını düzelt.
• Süre etiketlerini yerelleştir (0 = Kapalı, 30 sn, 60 sn).
• Sürümü tek yerden oku (yeni bağımlılık gerekirse önce sor).
• Excluded folders: silmeden önce onay, ardından geri al çubuğu.
• Testler: PreferencesController (varsayılan, kaydet/yükle, resetAll), SettingsSearchController (TR/EN eşleşme), SettingsRegistry bütünlüğü, ThemeSettings JSON, yedek anahtar testi.
Kabul: flutter analyze temiz, flutter test yeşil, TR/EN geçişinde ayar sayfalarında sabit metin kalmadı.
FAZ 2: YENİ ÖZELLİKLER (Gün 6–10)
Kural: Yalnızca mevcut mimarinin (just_audio, audio_service, audio_session, Drift, haudiotagger) karşılığı olan ayarlar eklenir. Her biri için önce tüketici noktasını bul; yoksa ekleme. Doğrula maddelerinin API desteğini kodda veya paket kaynağında teyit et; teyit edemezsen o maddeyi atla ve raporla.
Gün 6: Çalma ve ses oturumu
• Kesinti davranışı: audio_session_datasource.dart pause ve duck kesintilerini zaten işliyor (duck’ta sesi 0.3’e indirip bitince 1.0’a döndürüyor; kesinti bitince devam etme yeri «Gün 21» notuyla boş). Ayarlar: «Kesintide sesi kısmak yerine duraklat» ve «Kesinti bitince devam et». Datasource şu an yalnız shouldPauseOnUnplug göstergesini alıyor; yeni göstergeleri aynı kalıpla ekle. Ek bulgu (Doğrula): duck sonrası setVolume(1.0) kullanıcının ses seviyesini eziyor olabilir; önceki seviyeyi sakla.
• İleri ve geri atlama süresini ayır (şu an tek seekIntervalSeconds; PlayerController.fastForward ve rewind).
• ReplayGain: kip (parça/albüm) ve ön kazanç. Doğrula: metadata_datasource.dart yalnızca parça kazancını okuyor; haudiotagger albüm kazancını veriyor mu? Vermiyorsa yalnız ön kazancı ekle.
• Uyku zamanlayıcısı: SleepTimerController zaten sönümleme süresini (fadeSeconds, varsayılan 10 sn) ve «parça sonunda bitir» modunu (isEndOfTrackMode) taşıyor. Ayarlar: varsayılan süre ve sönümleme süresi; tüketici startTimer çağrı noktaları (sleep_timer_sheet.dart).
Gün 7: Kitaplık
• Asgari dosya boyutu filtresi (SongModel.sizeBytes mevcut; _buildIndex içinde minDuration ile aynı yere).
• Varsayılan açılış sekmesi, sekme sırası ve gizleme: library_tabs_page.dart TabController(length: 5) ile sekmeleri sabit kuruyor; sekme listesini veriye çevir. Kayıtlı liste bozuk veya eksikse varsayılan sıraya dön.
• Şarkı listesi sıralaması: songs_page.dart’ta setSongSort ile sıralama mevcut. Doğrula: seçim kalıcı mı? Değilse kalıcılaştır ve varsayılan sıralama ayarı olarak sun.
• Dışlanan klasör ekleyince etkilenen şarkı sayısını göster.
Gün 8: Bildirim ve widget
• Karar: Bildirim sayfası bu planda yalnız yeniden adlandırılır («Bildirim önizlemesi»; l10n anahtarları ve ana sayfadaki açıklama dahil). Sayfada bugün gerçek ayar yok ve eklenmez. Gerçek bildirim ayarları (bildirimde görünecek kontroller), audio_handler.dart’taki MediaControl listesi okunup doğrulandıktan sonra ayrı iş olarak planlanır.
• Widget: şeffaf modda metin rengi sabit beyaz (music_widget.xml, MusicWidgetProvider.kt); açık duvar kâğıdında okunmayabilir. Metin rengini tercihe bağla (yalnızca mevcut RemoteViews yetenekleriyle). Cihazda Doğrula.
Gün 9: Veri ve sıfırlama
• «Ayarları varsayılana döndür»: PreferencesController.resetAll() ve l10n.resetAll metni var ama hiçbir ekrandan çağrılmıyor (arama yapıldı). Bağla; tema (ThemeController), dil (SettingsController) ve widget şeffaflığı için eşdeğer sıfırlama ekle. Onay diyaloğu zorunlu.
• Dinleme geçmişi ve istatistik temizleme (HistoryDao, StatsRepository mevcut), onaylı.
• Yalnızca ayarları dışa ve içe aktar (Gün 1’deki anahtar listesi + şema sürümü).
Gün 10: Şema sürümü ve kanıt tablosu
• playback_settings ve library_settings JSON’unda sürüm alanı yok. schemaVersion ekle (eksik = 1), geçiş fonksiyonu ve test yaz.
• PlaybackSettingsModel.fromJson tip dönüşümlerini alan bazlı varsayılana düşecek şekilde sağlamlaştır (int/double karışımı).
• Tüm ayarlar için kanıt tablosu üret ve docs/settings_matrix.md olarak yaz: ayar, arayüz, kalıcılık, tüketici, test.
FAZ 3: ARAYÜZ (Gün 11–14)
Genel bulgular: Ana ayar sayfası kart tabanlı (settings_home_page.dart), alt sayfalar üç farklı dilde: düz ListTile (Çalma, Kitaplık, Ses, Etiket), kartlı (Widget, Bildirim, Galeri) ve DropdownButton’lu SettingsChoiceTile. Ana sayfadaki satırlar registry’den değil elle yazılmış; iki kaynak ayrışabilir. Tema ayarları Galeri ve «Gelişmiş» olarak iki sayfaya bölünmüş ve tekrarlı (mod, kaynak, AMOLED). Çoğu anahtarın alt açıklaması yok.
Gün 11: Bilgi mimarisi
• Ana sayfa satırlarını registry kategorilerinden üret: Çalma · Ses · Kitaplık · Görünüm · Bildirim ve widget · Yedek ve veri · Hakkında. Tek doğruluk kaynağı.
• Arama sonuçlarında kategori yolu (ör. Görünüm › Tema) ve eşleşen ayarın yanında anlık kontrol; dokununca ilgili sayfaya gidip ayarı geçici vurgula.
Gün 12: Ortak bileşenler
• SettingsGroupCard, SettingsSwitchTile, SettingsChoiceTile ve settings_tile.dart’ı tek tasarım diline getir.
• 3 veya daha az seçenek için SegmentedButton, daha fazlası için bottom sheet radyo listesi; DropdownButton kullanımını kaldır.
• Her anahtara l10n alt açıklama; dokunma hedefi en az 48dp; Semantics etiketleri.
Gün 13: Sayfaların yeniden düzeni
• Çalma: «Denetim · Başlangıç davranışı · Ses işleme» grupları.
• Görünüm: Galeri ve Gelişmiş sayfalarını tek sayfada bölümlere ayır; sabit canlı önizleme; sayfa adını gösteren AppBar.
• Her sayfada «Bu sayfayı varsayılana döndür» (onaylı).
• Dışlanan klasörler: boş durum, kaydırarak silme ve geri al.
Gün 14: Erişilebilirlik, geniş ekran, kapanış
• Sistem yazı ölçeği 1.3 ve uygulama ölçeği 1.4 birlikte: tüm ayar sayfalarında taşma taraması.
• Geniş ekran: mevcut expanded_layout ve Responsive yardımcılarıyla iki bölmeli ayarlar.
• Açık, koyu, AMOLED ve yüksek kontrast için golden testler; TR ve EN metin taşması kontrolü.
• Final: flutter analyze sıfır uyarı, flutter test yeşil, settings_matrix.md güncel, değişiklik günlüğü.
Raporlama
Her günün sonunda yapay zekâdan şu tabloyu iste: görev, durum (yapıldı / kısmen / yapılamadı), kanıt (test adı veya dosya:satır), açık kalan risk. «Yapıldı» ancak kanıtla geçerlidir.