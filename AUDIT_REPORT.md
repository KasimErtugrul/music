🔍 State Management Denetimi — Resonance
Kapsam: 29 controller, binding'ler (InitialBinding/main), repository katmanı, UI sayfaları. Uzak ağaçtaki güncel hâli (7031982) inceledim. 7 yüksek, 12 orta, 8 düşük bulgu var. Dosya+satır+senaryo+öneri formatında:

🔴 Yüksek Öncelik (kullanıcının gördüğü davranış hataları)
1. Hariç tutulan klasör sonrası kütüphane bayat kalıyor
excluded_folders_controller.dart:30-40 — addFolder/removeFolder → _libraryRepo.rescan() çağırıyor ama LibraryController'ın Rx listelerini tazelemiyor (LibraryController'ın hiçbir stream dinleyicisi yok). Vault tarafındaki _applyFilterChange ise LibraryController.loadAll() çağırıyor → iki akış tutarsız.
Senaryo: Ayarlar → Hariç tutulan klasörler → klasör ekle → Kütüphane sekmesine dön → şarkılar hâlâ listede, pull-to-refresh yapana kadar kaybolmaz.
Öneri: Vault'taki _applyFilterChange deseni buraya da (isRegistered + loadAll).

2. Çalma listesine eklemede kopya yarışı (TOCTOU) — kuyruğundaki "duplicate engelleme" bulgusunun kökü
playlist_controller.dart:73-82 + playlist_picker_sheet.dart:48-52: isSongInPlaylist kontrolü (await'li DB sorgusu) ile add arasında pencere var; ListTile onTap'inde busy-guard yok.
Senaryo: Aynı satıra çift hızlı dokunuş → iki kontrol de false döner → aynı şarkı listede iki kez. Kontroller: tek satırlık isWorking guard'ı controller'da, ya da repo'da unique constraint + idempotent add.

3. Harici dosya niyeti izin/onboarding kapısını eziyor
external_open_controller.dart:24-35 + 54-77 — _handleInitial sabit 1500 ms bekleyip Get.offAllNamed(externalPlayer) yapıyor; route kontrolü yalnız "zaten externalPlayer'da mı".
Senaryo: Uygulama yeni kuruldu, kullanıcı dosya yöneticisinden "Resonance ile aç" dedi → splash/izin/onboarding ekranının üstüne offAllNamed → izin akışı atlanır, media izni olmadan playSong başarısız olur.
Öneri: _schedulePlay öncesi media.value.isGranted + mevcut route'un splash/permission/onboarding olup olmadığı kontrol edilmeli; izin yoksa URI saklanıp kapı tamamlandığında oynatılmalı.

4. Kapak-teması yarışı: hızlı geçişte tema eski kapağın renginde takılıyor
theme_controller.dart:218-238 — _updateArtworkTheme await'li kapak okumasından sonra hangi parça için yazdığını doğrulamıyor. (PlayerController'daki _updateFormatInfo:742 tam bu korumaya sahip: if (currentSong?.id == song.id).)
Senaryo: tema kaynağı "kapak" iken hızlıca 2-3 parça geçilir → eski parçanın ağır okuması en son biter → _lightArtworkScheme bir önceki kapağın paletiyle güncellenir ve parça değişene kadar öyle kalır.
Öneri: Aynı guard: okuma başında item.id yakala, await sonrası _lastMediaItem?.id == item.id değilse yazma.

5. Uyku zamanlayıcısında ses kısmada takılıyor (+5 dk ve yeni süre seçimi)
sleep_timer_controller.dart:32-33 + sleep_timer_sheet.dart:80,103,117 — startTimer varsayılanı resetVolume: false; fade sırasında (ses örn. 0.15'e inmişken) yeni süre seçilirse eski timer iptal edilir ama ses geri getirilmez; yeni kalan süre (ör. 305 sn) >_fadeSeconds olduğu için fade koşulu uzun süre yanlış kalır → ses dakikalarca kısık kalır.
Öneri: startTimer başlangıcında _fadeSeconds > 0 && volume < hedef ise sesi hedefe resetle (veya extension yolunda resetVolume: true).

6. Equalizer slider'ı: tik başına iç içe DB+platform yazımı, karışık eğri kalıcılaşabilir
equalizer_page.dart:299-301 (onChanged içinde unawaited ctrl.updateBand) + equalizer_controller.dart:127-135 — her sürükleme tiki: setGain (platform) + setBandGain + tüm bantları içeren saveGains. İç içe çağrılarda saveGains anlık görüntüsü yarışır → diske diğer bantların bayat değerleriyle karışık eğri yazılabilir; donanımda da setGain sırası karışır.
Öneri: Slider'da onChanged → sadece Rx/param güncelle, onChangeEnd'de tek seferlik persist; updateBand içinde basit bir yazım kuyruğu (önceki save promise'ını bekleyen zincir).

7. QueueController ölü kod + içinde gizli davranış hatası
queue_controller.dart — lib/test'te hiçbir yerden kullanılmıyor. Kullansaydı: playSong(song, queue: full) çağırdığı için playSong'un "yeni kuyruk" sözleşmesi gereği karıştırma/tekrar tercih varsayılanına çekilecekti — playFromQueue'nun (Bulgu 3) çözdüğü sorunun canlanması. Silinmeli ki yanlışlıkla kullanılmasın.

🟠 Orta Öncelik (yarışlar, ayrışmalar, hata sözleşmesi)
8. PlayerController'da 6 stream aboneliği + ever worker saklanmıyor; onClose yok — player_controller.dart:110-172, 190. Controller permanent: true olduğu için normal ömürde sorun çıkmıyor; ama Get.reset()/test/hot-restart'ta "ghost update" ve sızıntı. Ayrıca _saveQueueState çağrıları serileştirilmiyor (position throttle'ı + playbackState dinleyicisi eşzamanlı) → bayat pozisyon üstüne yazılıp restore'da 5 sn geri sıçrama olabilir. Öneri: Abonelikleri List<StreamSubscription>'a topla + onClose'da iptal; _saveQueueState'i tek sıra (isWorking guard/coalescing) yap — HomeWidgetController'ın _requestSync döngüsü birebir bu deseni zaten kullanıyor.

9. Kuyruk mutasyonlarında yerel-önce/hata-rollback yok — player_controller.dart:535-540 (removeFromQueue), 550-554 (reorderQueue), 542-546 (clearQueue): songQueue Rx'i await'ten önce değiştiriliyor; _repository.* hata atarsa UI kuyruğu ile oynatıcı kuyruğu kalıcı ayrışır (playSong'daki previousQueue rollback deseni burada yok). Ayrıca async pencerede currentQueueIndex ↔ songQueue kayması kuyruk sayfasında yanlış vurgu gösterebilir.

10. LibraryController.loadAll sıralama yarışına açık — library_controller.dart:78-94: setSongSort'taki if (sort != songSort.value) return; koruması loadAll/_reloadLists'te yok. Senaryo: açılış yüklemesi sürerken kullanıcı sıralamayı değiştirir → setSongSort yazdıktan sonra loadAll bayat sırayla üstüne yazar. Ayrıca refresh() isAutoScanning kapsamında değil → manuel yenileme + otomatik tarama eşzamanlı koşabilir; refresh sonrası _lastScanAt güncellenmediğinden Resume hemen yeniden tarar.

11. Favori toggle: optimistik güncelleme + rollback yok — favorite_controller.dart:19-26: Rx set önce çevriliyor, DB sonrakı; _repo.toggleFavorite hata atarsa kalp yanlış tarafta donar (watch stream emit üretmeyeceği için kendiliğinden düzelmez). try/catch + eski değere dön.

12. EQ toggleEnabled aynı desen — equalizer_controller.dart:116-125: isEnabled.value = value önce, repo sonra; hata durumunda anahtar açık görünür ama EQ kapalı.

13. StatsController.setPeriod bayat sonuç yarışı — stats_controller.dart:38-53: hızlı dönem değiştirmede iki loadStats iç içe girer, eski dönem verisi en son yazılabilir (staleness token yok; setSongSort'taki guard deseni buraya da).

14. HomeController._favSub async callback yarışı + sessiz hata — home_controller.dart:47-50: iki hızlı favori değişiminde _updateFavoriteSongs'ın await'i kesişir, eski liste geç yazılabilir. loadAll hatayı yalnız logluyor → hata durumunda boş ana sayfa, kullanıcıya sinyal yok (hasError alanı hiç yok).

15. Yükleyici metotlarda hata sözleşmesi tutarsız — playlist_controller.dart:30-45 (loadPlaylists catch'siz; onInit'te DB hatası → işlenmemiş async hata), smart_playlist_controller.dart:12-19, stats_controller.dart:44-53, history_controller.dart:13-19. Tutarlı sözleşme önerisi: ya hasError Rx'i (LibraryController gibi) ya da catch'siz fırlat + UI'da işle; try/finally yalnız başına hata yutmaz.

16. Watch aboneliklerinde onError yok — history_controller.dart:15, favorite_controller.dart:14, vault_controller.dart:84 (onError boş yutuyor ama abonelik yaşıyor mu garanti değil): Drift watch stream'i hata verirse abonelik ölürse geçmiş listesi/favori rozetleri sonsuza dek donar, isLoading true takılır.

17. Yedek içe aktarmada açık çalma listesi detayı tazelenmiyor — live_settings_reload.dart:77-86: reloadLivePlaylistControllers yalnız loadPlaylists() çağırıyor; kullanıcı playlist detay sayfasındaysa currentSongs/currentPlaylist bayat kalır (silinmiş listenin şarkıları ekranda kalır). Detay açıkken loadPlaylistDetail de eklenmeli.

18. Kasadaki şarkı çalmaya devam edebiliyor — vault_controller.dart:108-119: ban() çalan parçayı durdurmuyor; koruma yalnız playSong kapısında. Tasarım kararı olabilir ama "ban → çalmaya devam ediyor" tutarsız bir durum; en azından currentSong == song ise duraklat/sonraki önerilir.

19. Ayarlar arama sorgusu sekmeler arasında yaşıyor — settings_home_page.dart:91: Get.put(SettingsSearchController()) build içinde; IndexedStack sayfayı diri tuttuğundan controller asla silinmez, sorgu sıfırlanmaz → ayarlara dönüşte eski filtre hâlâ aktif. initState'e taşı + sayfa açılışında query.value = ''.

🟡 Düşük Öncelik (sağlamlaştırma)
SettingsController._load try/catch yok (settings_controller.dart:21-24) → platform hatasında isLoading true takılı; app.dart:15-23 kök kapısı sonsuza dek spinner gösterir. (ThemeRepository bozuk JSON'da null'a düşüyor — o taraf güvenli.)
ThemeController._update (theme_controller.dart:249): saveActiveTheme unawaited + catch'siz → tema yazımı hata verirse işlenmemiş async hata (zone log).
PlayerController._formatCache sınırsız (player_controller.dart:82) — oturum boyunca şarkı sayınca kadar büyür; pratikte küçük, LRU şart değil.
SleepTimer.startEndOfTrack.handleEnd (sleep_timer_controller.dart:70-79): pause() hata atarsa hasPaused=true kalmış, abonelik iptal edilmez; try/finally ile cancel edilmeli.
PreferencesController.set* tam model save'i kanal FIFO'suna dayanıyor (preferences_controller.dart:68-137) — tek izolatte şu an güvenli ama kırılgan; savePlayback'i sıralı kuyruk (önceki await'i bekleyen zincir) yapmak sağlamlaştırır.
VaultController.setPin iki ayrı await setString (vault_controller.dart:160-161): salt yazılıp hash yazılmadan çökme → yarım durum. Tek atomik yazım (prefs setValues / kompozit anahtar) önerilir.
PlaylistBinding ölü kayıt (playlist_binding.dart) — PlaylistController artık InitialBinding'de kalıcı; binding'i route'lardan sökmek kafa karışıklığını önler.
_restoreQueue fallback dalında prefCtrl.ready beklenmiyor (player_controller.dart:319 vs 292) — pratikte microtask sıralaması yüzünden pencere çok küçük ama sözleşme tutarsız; bir satırla kapanır.
✅ Beğenilen desenler (bunları yayalım)
Desen
Nerede
Kime taşınmalı
Coalescing döngü (_dirty/_running)	HomeWidgetController:55	_saveQueueState (Bulgu 8)
Staleness guard (if (_currentPath == songPath))	WaveformController:23, setSongSort:123	_updateArtworkTheme (Bulgu 4), StatsController (13), HomeController (14)
Optimistik mutasyon + finally rollback	reorderSongs:141, playSong:400-411	removeFromQueue (9), FavoriteController (11), toggleEnabled (12)
Generation sayacı (fade iptali)	player_repository.dart:110-139	— örnek düzey
