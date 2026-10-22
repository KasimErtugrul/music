import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/dynamic_theme_service.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/data/repositories/library_repository.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  ThemeController(this._repo, this._player, this._libraryRepo);
  final ThemeRepository _repo;
  final PlayerController _player;
  final LibraryRepository _libraryRepo;

  final settings = const ThemeSettings().obs;
  final isLoading = true.obs;
  
  ColorScheme? _artworkScheme;
  Timer? _scheduledTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadActive();
    
    // Şarkı değiştiğinde kapağı dinle
    _player.currentItem.listen((item) {
      if (settings.value.themeSource == 'artwork') {
        _updateArtworkTheme();
      }
    });

    // Zamanlı tema için her dakika kontrol et
    _scheduledTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (settings.value.themeMode == ThemeMode.system || _isScheduledTime()) {
        // GetMaterialApp zaten system mode'u işler, eğer zamanlıysa manuel zorla
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduledTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActive() async {
    final loaded = await _repo.loadActiveTheme();
    if (loaded != null) settings.value = loaded;
    if (settings.value.themeSource == 'artwork') {
       _updateArtworkTheme();
    }
    isLoading.value = false;
  }

  Future<void> _updateArtworkTheme() async {
    final item = _player.currentItem.value;
    if (item == null) return;
    
    final songId = int.tryParse(item.id.split('/').last);
    if (songId == null) return;

    final bytes = await _libraryRepo.artwork(songId);
    if (bytes != null) {
      final scheme = await DynamicThemeService.fromArtwork(
        bytes, 
        brightness: Get.isDarkMode ? Brightness.dark : Brightness.light,
      );
      if (scheme != null) {
        _artworkScheme = scheme;
        // UI'ı yeniden çizmek için settings'i tetikle (aynı değerle)
        settings.refresh();
      }
    }
  }

  void _update(ThemeSettings next) {
    settings.value = next;
    _repo.saveActiveTheme(next);
    if (next.themeSource == 'artwork') {
      _updateArtworkTheme();
    } else {
      _artworkScheme = null;
    }
  }

  ThemeData lightTheme([ColorScheme? sysScheme]) => ThemeEngine.light(
    settings.value, 
    dynamicScheme: _artworkScheme ?? (settings.value.themeSource == 'system' ? sysScheme : null),
  );
  
  ThemeData darkTheme([ColorScheme? sysScheme]) => ThemeEngine.dark(
    settings.value, 
    dynamicScheme: _artworkScheme ?? (settings.value.themeSource == 'system' ? sysScheme : null),
  );

  ThemeMode get themeMode {
    if (settings.value.themeMode == ThemeMode.system && _isScheduledTime()) {
      return ThemeMode.dark; // Zamanlıysa koyuya zorla
    }
    return settings.value.themeMode;
  }

  bool _isScheduledTime() {
    final now = TimeOfDay.now();
    final start = TimeOfDay(hour: settings.value.scheduledDarkStartHour, minute: settings.value.scheduledDarkStartMinute);
    final end = TimeOfDay(hour: settings.value.scheduledDarkEndHour, minute: settings.value.scheduledDarkEndMinute);
    
    final nowMins = now.hour * 60 + now.minute;
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;

    if (startMins < endMins) {
      return nowMins >= startMins && nowMins < endMins;
    } else {
      return nowMins >= startMins || nowMins < endMins;
    }
  }

  void setSettings(ThemeSettings s) => _update(s);
  void setMode(ThemeMode mode) => _update(settings.value.copyWith(themeMode: mode));
  void setThemeSource(String source) => _update(settings.value.copyWith(themeSource: source));
  void setSeed(Color color) => _update(settings.value.copyWith(seedColor: color));
  void setAmoled(bool v) => _update(settings.value.copyWith(amoled: v));
  void setHighContrast(bool v) => _update(settings.value.copyWith(highContrast: v));
  void setSurfaceTint(bool v) => _update(settings.value.copyWith(surfaceTint: v));
  void setRoundedCorners(bool v) => _update(settings.value.copyWith(roundedCorners: v));
  void setDensity(VisualDensity d) => _update(settings.value.copyWith(density: d));
  void setFont(String f) => _update(settings.value.copyWith(fontFamily: f));
  void setTextScale(double s) => _update(settings.value.copyWith(textScale: s));
  void setPlayer(PlayerThemeExtension p) => _update(settings.value.copyWith(player: p));
  void setListViewMode(String m) => _update(settings.value.copyWith(listViewMode: m));
  void setScheduledDark(int startH, int startM, int endH, int endM) =>
      _update(settings.value.copyWith(
        scheduledDarkStartHour: startH, scheduledDarkStartMinute: startM,
        scheduledDarkEndHour: endH, scheduledDarkEndMinute: endM,
      ));
}