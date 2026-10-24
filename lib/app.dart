import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_pages.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

class ResonanceApp extends StatelessWidget {
  const ResonanceApp({super.key, this.initialRoute = AppPages.initial});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = Get.find<SettingsController>();
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() {
      if (settingsCtrl.isLoading.value || themeCtrl.isLoading.value) {
        // Yükleme sırasında Navigator'ı yıkmamak için sadece boş bir ekran dönüyoruz
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }

      final langCode = settingsCtrl.settings.value?.languageCode ?? 'system';
      final locale = switch (langCode) {
        'tr' => const Locale('tr'),
        'en' => const Locale('en'),
        _ => null,
      };

      return GetMaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: themeCtrl.lightTheme(),
        darkTheme: themeCtrl.darkTheme(),
        themeMode: themeCtrl.themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: initialRoute,
        getPages: AppPages.routes,
        // initialBinding KALDIRILDI (main.dart'ta var)
      );
    });
  }
}