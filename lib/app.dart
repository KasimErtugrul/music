import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/bindings/initial_binding.dart';
import 'package:resonance/core/routes/app_pages.dart';
import 'package:resonance/core/theme/app_theme.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';

class ResonanceApp extends StatelessWidget {
  const ResonanceApp({super.key, this.initialRoute = AppPages.initial});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = Get.find<SettingsController>();

    return Obx(() {
      if (settingsCtrl.isLoading.value) {
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settingsCtrl.currentThemeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialBinding: InitialBinding(),
        initialRoute: initialRoute,
        getPages: AppPages.routes,
      );
    });
  }
}