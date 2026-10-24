import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/dynamic_theme_service.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  ThemeController(this._repo, this._playerStream, this._libraryRepo);
  final ThemeRepository _repo;
  final Stream<MediaItem?> _playerStream;
  final LibraryRepository _libraryRepo;

  final settings = const ThemeSettings().obs;
  final isLoading = true.obs;
  
  ColorScheme? _lightArtworkScheme;
  ColorScheme? _darkArtworkScheme;
  Timer? _scheduledTimer;
  ThemeMode? _currentComputedMode;
  MediaItem? _lastMediaItem; // Son çalan şarkıyı tutar

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadActive();
    
    _playerStream.listen((item) {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && settings.value.themeMode == ThemeMode.system) {
      _applyThemeIfChanged();
    }
  }

  Future<void> _loadActive() async {
    final loaded = await _repo.loadActiveTheme();
    if (loaded != null) settings.value = loaded;
    isLoading.value = false;
    _applyThemeIfChanged(force: true);
  }

  Future<void> _updateArtworkTheme(MediaItem? item) async {
    if (item == null) return;
    final songId = int.tryParse(item.id.split('/').last);
    if (songId == null) return;

    final bytes = await _libraryRepo.artwork(songId);
    if (bytes != null) {
      final baseScheme = await DynamicThemeService.fromArtwork(bytes, brightness: Brightness.light);
      if (baseScheme != null) {
        _lightArtworkScheme = baseScheme;
        _darkArtworkScheme = ColorScheme.fromSeed(seedColor: baseScheme.primary, brightness: Brightness.dark);
        _applyThemeIfChanged(force: true);
      }
    }
  }

  void _update(ThemeSettings next) {
    settings.value = next;
    _repo.saveActiveTheme(next);
    if (next.themeSource == 'artwork') {
      _updateArtworkTheme(_lastMediaItem); // Hata veren Get.find kaldırıldı, son item kullanılıyor
    } else {
      _lightArtworkScheme = null;
      _darkArtworkScheme = null;
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

  ThemeData lightTheme() => ThemeEngine.light(settings.value, dynamicScheme: _lightArtworkScheme);
  ThemeData darkTheme() => ThemeEngine.dark(settings.value, dynamicScheme: _darkArtworkScheme);

  ThemeMode get themeMode => _computeThemeMode();

  ThemeMode _computeThemeMode() {
    if (settings.value.themeMode == ThemeMode.system && _isScheduledTime()) {
      return ThemeMode.dark;
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
    if (startMins < endMins) return nowMins >= startMins && nowMins < endMins;
    return nowMins >= startMins || nowMins < endMins;
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