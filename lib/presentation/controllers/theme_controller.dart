import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/core/theme/dynamic_theme_service.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  ThemeController(
    this._repo,
    this._playerStream,
    this._libraryRepo, {
    this.systemSchemeLoader,
  });
  final ThemeRepository _repo;
  final Stream<MediaItem?> _playerStream;
  final LibraryRepository _libraryRepo;

  /// Bulgu 4 (test edilebilirlik): Material You sorgusu tek kapıdan geçer.
  /// Canlı uygulamada null kalır ve varsayılan kapı devreye girer
  /// ([_querySystemScheme]: DynamicColorPlugin.getCorePalette + flutter
  /// ColorScheme köprüsü). Testler platform kanalını bu kapıdan sahteleyip
  /// sorgunun GEÇ tamamlanmasını denetleyebilir. Dönüş, flutter/material
  /// ColorScheme çiftidir; böylece testlerin paket tipine (CorePalette)
  /// ihtiyacı olmaz.
  final Future<({ColorScheme light, ColorScheme dark})?> Function()?
  systemSchemeLoader;

  final settings = const ThemeSettings().obs;
  final isLoading = true.obs;

  // Kapaktan türetme (artwork) ve sistem (Material You) şemaları aynı kanaldan
  // beslenir: ThemeEngine, dynamicScheme doluysa onu kullanır.
  ColorScheme? _lightArtworkScheme;
  ColorScheme? _darkArtworkScheme;
  Timer? _scheduledTimer;
  ThemeMode? _currentComputedMode;
  MediaItem? _lastMediaItem; // Son çalan şarkıyı tutar

  StreamSubscription<dynamic>? _playerSub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadActive();

    _playerSub = _playerStream.listen((item) {
      _lastMediaItem = item;
      if (settings.value.themeSource == 'artwork') _updateArtworkTheme(item);
    });

    _scheduledTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (settings.value.themeMode == ThemeMode.system) _applyThemeIfChanged();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduledTimer?.cancel();
    super.dispose();
  }

  /// Gün 19: GetX silmede (delete/reset) yalnız onClose koşar; dispose()
  /// çağrılmaz. Zamanlayıcı sızmasın diye iptal burada da yapılır.
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduledTimer?.cancel();
    _playerSub?.cancel();

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        settings.value.themeMode == ThemeMode.system) {
      _applyThemeIfChanged();
    }
  }

  Future<void> _loadActive() async {
    final loaded = await _repo.loadActiveTheme();
    if (loaded != null) settings.value = loaded;
    isLoading.value = false;
    _applyThemeIfChanged(force: true);

    // Görev 3.1: açılışta kaynak "system" ise Android 12+ sistem paletini
    // sorgula. dynamic_color'dan gelen şema ThemeEngine'in dynamicScheme
    // kanalına beslenir; desteklenmeyen cihazda (Android 11 ve altı) null
    // döner ve seed paleti etkin kalır.
    if (settings.value.themeSource == 'system') {
      await _loadSystemScheme();
    }
  }

  /// Gün 1: yedek içe aktarma sonrası kayıtlı temayı yeniden okuyup uygular.
  /// Açılıştaki [_loadActive] ile aynı yolu izler; yalnızca isLoading'i
  /// dokunmaz (açılış göstergesi değil, canlı güncelleme).
  Future<void> reload() async {
    final loaded = await _repo.loadActiveTheme();
    if (loaded != null) settings.value = loaded;
    _applyThemeIfChanged(force: true);
    if (settings.value.themeSource == 'system') {
      await _loadSystemScheme();
    }
  }

  /// Görev 3.1: Material You (Android 12+ dinamik renk) şeması.
  ///
  /// ÖNEMLİ (pub.dev API + changelog + paket kaynağıyla doğrulandı):
  /// 1) dynamic_color paketinde DynamicColorPlugin.getScheme() diye bir metot
  ///    YOKTUR (planın özet yaması hatalıydı); paketin gerçek API'si
  ///    DynamicColorPlugin.getCorePalette() + CorePaletteToColorScheme
  ///    extension'ıdır. CorePalette'ten hem açık hem koyu şema doğrudan
  ///    üretilir: koyu taraf light.primary'den türetilmez, Material You'nun
  ///    gerçek koyu tonları kullanılır.
  /// 2) dynamic_color 2.0.0'dan itibaren flutter/material yerine material_ui
  ///    paketine göç etti; toColorScheme() artık material_ui'nin
  ///    ColorScheme'ini döndürür. Proje flutter/material'ın ColorScheme'ini
  ///    kullandığından iki tip aynı adı taşısa da FARKLI sınıflardır
  ///    ("A value of type 'ColorScheme' can't be assigned to a variable of
  ///    type 'ColorScheme?'" hatasının kökü budur). Dönüş değeri bu yüzden
  ///    rol rol flutter/material ColorScheme'ine köprülenir: renk adayları
  ///    her iki tarafta da dart:ui Color olduğundan taşımada kayıp yoktur
  ///    ve material_ui projeye bağımlılık olarak eklenmez. Köprü deseni
  ///    (fromSeed + copyWith), dynamic_color 2.x'in kendi uygulamasının
  ///    aynısıdır; yalnızca hedef tip farklıdır.
  ///
  /// getCorePalette() desteklenmeyen cihazlarda (Android 11 ve altı) null
  /// döner veya PlatformException atar; her iki durumda da sessizce seed'e
  /// düşülür ve arayüz çökmez.
  ///
  /// Not: kapatıp açma sırasında eski şemanın kalıntısını bırakmamak için
  /// önce kanallar sıfırlanır; başarılı sorguda tekrar doldurulur.
  Future<void> _loadSystemScheme() async {
    _lightArtworkScheme = null;
    _darkArtworkScheme = null;
    try {
      final schemePair =
          await (systemSchemeLoader?.call() ?? _querySystemScheme());
      // Bulgu 4: sorgu sürerken kullanıcı renk kaynağını değiştirdiyse
      // kanallar bayat paletle DOLDURULMAZ; _update zaten sıfırladı, öyle
      // kalsın. Yeni kaynak kendi kanalını kendi çağrısında kurar.
      if (settings.value.themeSource != 'system') return;
      if (schemePair == null) {
        // Desteklenmiyor: seed paletle devam et.
        _applyThemeIfChanged(force: true);
        return;
      }
      _lightArtworkScheme = schemePair.light;
      _darkArtworkScheme = schemePair.dark;
      _applyThemeIfChanged(force: true);
    } on Object {
      // Paket/Platform hatası: seed'te kal, arayüzü bozma.
      _applyThemeIfChanged(force: true);
    }
  }

  /// Görev 3.1: Material You (Android 12+ dinamik renk) sorgusu ve
  /// flutter/material ColorScheme köprüsü. Eskiden _loadSystemScheme
  /// gövdesiydi; Bulgu 4 test kapısı için BİREBİR taşındı (davranış aynı).
  ///
  /// ÖNEMLİ (pub.dev API + changelog + paket kaynağıyla doğrulandı):
  /// 1) dynamic_color paketinde DynamicColorPlugin.getScheme() diye bir metot
  ///    YOKTUR (planın özet yaması hatalıydı); paketin gerçek API'si
  ///    DynamicColorPlugin.getCorePalette() + CorePaletteToColorScheme
  ///    extension'ıdır. CorePalette'ten hem açık hem koyu şema doğrudan
  ///    üretilir: koyu taraf light.primary'den türetilmez, Material You'nun
  ///    gerçek koyu tonları kullanılır.
  /// 2) dynamic_color 2.0.0'dan itibaren flutter/material yerine material_ui
  ///    paketine göç etti; toColorScheme() artık material_ui'nin
  ///    ColorScheme'ini döndürür. Proje flutter/material'ın ColorScheme'ini
  ///    kullandığından iki tip aynı adı taşısa da FARKLI sınıflardır
  ///    ("A value of type 'ColorScheme' can't be assigned to a variable of
  ///    type 'ColorScheme?'" hatasının kökü budur). Dönüş değeri bu yüzden
  ///    rol rol flutter/material ColorScheme'ine köprülenir: renk adayları
  ///    her iki tarafta da dart:ui Color olduğundan taşımada kayıp yoktur
  ///    ve material_ui projeye bağımlılık olarak eklenmez. Köprü deseni
  ///    (fromSeed + copyWith), dynamic_color 2.x'in kendi uygulamasının
  ///    aynısıdır; yalnızca hedef tip farklıdır.
  ///
  /// getCorePalette() desteklenmeyen cihazlarda (Android 11 ve altı) null
  /// döner veya PlatformException atar; her iki durumda da sessizce seed'e
  /// düşülür ve arayüz çökmez.
  Future<({ColorScheme light, ColorScheme dark})?> _querySystemScheme()
      async {
    final palette = await DynamicColorPlugin.getCorePalette();
    if (palette == null) return null;
    // material_ui'nin ColorScheme'i: tip adı dosyada anılmadığından
    // import gerekmez, tip çıkarımıyla kullanılır.
    final muLight = palette.toColorScheme(brightness: Brightness.light);
    final muDark = palette.toColorScheme(brightness: Brightness.dark);
    // flutter/material ColorScheme'ine köprü (yukarıdaki 2. not).
    // fromSeed, yeni rol adlarını (surfaceContainer* vb.) doldurur;
    // copyWith, OS'tan gelen gerçek dinamik palet rollerini ezer.
    final light = ColorScheme.fromSeed(
      seedColor: muLight.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: muLight.primary,
      onPrimary: muLight.onPrimary,
      primaryContainer: muLight.primaryContainer,
      onPrimaryContainer: muLight.onPrimaryContainer,
      secondary: muLight.secondary,
      onSecondary: muLight.onSecondary,
      secondaryContainer: muLight.secondaryContainer,
      onSecondaryContainer: muLight.onSecondaryContainer,
      tertiary: muLight.tertiary,
      onTertiary: muLight.onTertiary,
      tertiaryContainer: muLight.tertiaryContainer,
      onTertiaryContainer: muLight.onTertiaryContainer,
      error: muLight.error,
      onError: muLight.onError,
      errorContainer: muLight.errorContainer,
      onErrorContainer: muLight.onErrorContainer,
      surface: muLight.surface,
      onSurface: muLight.onSurface,
      onSurfaceVariant: muLight.onSurfaceVariant,
      outline: muLight.outline,
      outlineVariant: muLight.outlineVariant,
      shadow: muLight.shadow,
      scrim: muLight.scrim,
      inverseSurface: muLight.inverseSurface,
      onInverseSurface: muLight.onInverseSurface,
      inversePrimary: muLight.inversePrimary,
      surfaceTint: muLight.surfaceTint,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: muDark.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: muDark.primary,
      onPrimary: muDark.onPrimary,
      primaryContainer: muDark.primaryContainer,
      onPrimaryContainer: muDark.onPrimaryContainer,
      secondary: muDark.secondary,
      onSecondary: muDark.onSecondary,
      secondaryContainer: muDark.secondaryContainer,
      onSecondaryContainer: muDark.onSecondaryContainer,
      tertiary: muDark.tertiary,
      onTertiary: muDark.onTertiary,
      tertiaryContainer: muDark.tertiaryContainer,
      onTertiaryContainer: muDark.onTertiaryContainer,
      error: muDark.error,
      onError: muDark.onError,
      errorContainer: muDark.errorContainer,
      onErrorContainer: muDark.onErrorContainer,
      surface: muDark.surface,
      onSurface: muDark.onSurface,
      onSurfaceVariant: muDark.onSurfaceVariant,
      outline: muDark.outline,
      outlineVariant: muDark.outlineVariant,
      shadow: muDark.shadow,
      scrim: muDark.scrim,
      inverseSurface: muDark.inverseSurface,
      onInverseSurface: muDark.onInverseSurface,
      inversePrimary: muDark.inversePrimary,
      surfaceTint: muDark.surfaceTint,
    );
    return (light: light, dark: dark);
  }

  Future<void> _updateArtworkTheme(MediaItem? item) async {
    if (item == null) return;
    final songId = int.tryParse(item.id.split('/').last);
    if (songId == null) return;
    // Bulgu 4: bayatlık kilidi — okuma BAŞINDA hangi parça için
    // çalıştığımız yakalanır (PlayerController._updateFormatInfo'daki
    // «if (currentSong?.id == song.id)» korumasının aynısı). Kapak okuması
    // ve palet hesabı await'lidir; bu sırada çalan parça değişirse veya
    // kullanıcı renk kaynağını değiştirirse (_update kanalları sıfırlar)
    // bu hesabın YAZIMI atılır: hızlı parça geçişinde tema eski kapağın
    // rengine takılmaz, kaynak değişiminde de eski kapak paleti yeni
    // kaynağın üstüne yazılamaz.
    final requestedItemId = item.id;

    final bytes = await _libraryRepo.artwork(songId);
    if (!_isArtworkRequestCurrent(requestedItemId)) return;
    if (bytes != null) {
      final baseScheme = await DynamicThemeService.fromArtwork(
        bytes,
        brightness: Brightness.light,
      );
      if (baseScheme != null) {
        // Palet hesabı da async: yazım öncesi yeniden doğrula.
        if (!_isArtworkRequestCurrent(requestedItemId)) return;
        _lightArtworkScheme = baseScheme;
        _darkArtworkScheme = ColorScheme.fromSeed(
          seedColor: baseScheme.primary,
          brightness: Brightness.dark,
        );
        _applyThemeIfChanged(force: true);
      }
    }
  }

  /// Bulgu 4: [requestedItemId] için bekleyen okumanın yazımı hâlâ
  /// güncel mi? Hem parça hem kaynak değişmemiş olmalı.
  bool _isArtworkRequestCurrent(String requestedItemId) =>
      _lastMediaItem?.id == requestedItemId &&
      settings.value.themeSource == 'artwork';

  void _update(ThemeSettings next) {
    // Gün 3: önce/sonra karşılaştırması — pahalı işler (kapak yeniden okuma,
    // Material You sorgusu) yalnız kaynak GERÇEKTEN değiştiğinde yapılır.
    // Eskiden her alan değişiminde (ör. amoled anahtarı) artwork/system
    // kanalı yeniden kuruluyordu.
    final prev = settings.value;
    final sourceChanged = prev.themeSource != next.themeSource;

    settings.value = next;
    // Denetim düşük öncelik: saveActiveTheme unawaited + catch'sizdi; tema
    // yazımı patlarsa işlenmemiş async hata zone'a düşüyordu. Hata günlüğe
    // yazılır; bellek içi durum (settings.value) güncel kalır ve sonraki
    // değişiklik yeniden kalıcılığı dener.
    unawaited(_persistTheme(next));

    if (sourceChanged) {
      if (next.themeSource == 'artwork') {
        _updateArtworkTheme(
          _lastMediaItem,
        ); // Hata veren Get.find kaldırıldı, son item kullanılıyor
      } else if (next.themeSource == 'system') {
        // Görev 3.1: sistem paleti kanalı (Material You).
        _loadSystemScheme();
      } else {
        _lightArtworkScheme = null;
        _darkArtworkScheme = null;
      }
    }
    _applyThemeIfChanged(force: true);
  }

  void _applyThemeIfChanged({bool force = false}) {
    final newMode = _computeThemeMode();
    if (force || newMode != _currentComputedMode) {
      _currentComputedMode = newMode;
      Get.changeThemeMode(newMode);
    }
  }

  ThemeData lightTheme() =>
      ThemeEngine.light(settings.value, dynamicScheme: _lightArtworkScheme);
  ThemeData darkTheme() =>
      ThemeEngine.dark(settings.value, dynamicScheme: _darkArtworkScheme);

  ThemeMode get themeMode => _computeThemeMode();

  ThemeMode _computeThemeMode() {
    // Gün 3 (Karar): zamanlama yalnız scheduledDarkEnabled açıkken uygulanır;
    // kapalıyken saklanan saat aralığı yok sayılır.
    if (settings.value.themeMode == ThemeMode.system &&
        settings.value.scheduledDarkEnabled &&
        _isScheduledTime()) {
      return ThemeMode.dark;
    }
    return settings.value.themeMode;
  }

  bool _isScheduledTime() {
    final now = TimeOfDay.now();
    final start = TimeOfDay(
      hour: settings.value.scheduledDarkStartHour,
      minute: settings.value.scheduledDarkStartMinute,
    );
    final end = TimeOfDay(
      hour: settings.value.scheduledDarkEndHour,
      minute: settings.value.scheduledDarkEndMinute,
    );
    final nowMins = now.hour * 60 + now.minute;
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    if (startMins < endMins) return nowMins >= startMins && nowMins < endMins;
    return nowMins >= startMins || nowMins < endMins;
  }

  void setSettings(ThemeSettings s) => _update(s);
  void setMode(ThemeMode mode) =>
      _update(settings.value.copyWith(themeMode: mode));
  void setThemeSource(String source) =>
      _update(settings.value.copyWith(themeSource: source));
  void setSeed(Color color) =>
      _update(settings.value.copyWith(seedColor: color));
  void setAmoled(bool v) => _update(settings.value.copyWith(amoled: v));
  void setHighContrast(bool v) =>
      _update(settings.value.copyWith(highContrast: v));
  void setSurfaceTint(bool v) =>
      _update(settings.value.copyWith(surfaceTint: v));
  void setRoundedCorners(bool v) =>
      _update(settings.value.copyWith(roundedCorners: v));
  void setDensity(VisualDensity d) =>
      _update(settings.value.copyWith(density: d));
  void setFont(String f) => _update(settings.value.copyWith(fontFamily: f));
  void setTextScale(double s) => _update(settings.value.copyWith(textScale: s));
  void setPlayer(PlayerThemeExtension p) =>
      _update(settings.value.copyWith(player: p));
  void setListViewMode(String m) =>
      _update(settings.value.copyWith(listViewMode: m));

  /// Gün 3 (Karar): zamanlanmış koyu mod anahtarı.
  void setScheduledDarkEnabled(bool v) =>
      _update(settings.value.copyWith(scheduledDarkEnabled: v));

  /// Gün 3: özel tema uygulaması — Karar uyarınca yalnız RENK ve ŞEKİL
  /// alanları alınır (seed/amoled/highContrast/surfaceTint/roundedCorners/
  /// density). Mod, kaynak, yazı tipi, yazı ölçeği, oynatıcı stili, liste
  /// görünümü ve zamanlama saatleri kullanıcının kendi tercihleri olarak
  /// korunur.
  void applyCustomTheme(ThemeSettings custom) => _update(
    settings.value.copyWith(
      seedColor: custom.seedColor,
      amoled: custom.amoled,
      highContrast: custom.highContrast,
      surfaceTint: custom.surfaceTint,
      roundedCorners: custom.roundedCorners,
      density: custom.density,
    ),
  );

  /// Gün 3: yazı ölçeği sürükleme önizlemesi. Rx'i günceller ve uygulamayı
  /// yeniden çizer (mevcut yeniden çizim mekanizması: zorunlu mod uygulaması)
  /// ama diske YAZMAZ; kalıcılık yalnız [commitTextScale] yapar. Böylece
  /// kaydırıcı her kadimde SharedPreferences'a yazılmaz.
  void previewTextScale(double s) {
    settings.value = settings.value.copyWith(textScale: s);
    _applyThemeIfChanged(force: true);
  }

  /// Gün 3: sürükleme bırakıldığında önizlenen ölçeği diske yazar.
  Future<void> _persistTheme(ThemeSettings next) async {
    try {
      await _repo.saveActiveTheme(next);
    } on Object catch (e, st) {
      AppLog.error(e, st, source: 'ThemeController._update');
    }
  }

  Future<void> commitTextScale() => _repo.saveActiveTheme(settings.value);

  void setScheduledDark(int startH, int startM, int endH, int endM) => _update(
    settings.value.copyWith(
      scheduledDarkStartHour: startH,
      scheduledDarkStartMinute: startM,
      scheduledDarkEndHour: endH,
      scheduledDarkEndMinute: endM,
    ),
  );
}
