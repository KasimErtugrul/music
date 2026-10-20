import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/bindings/initial_binding.dart';
import 'package:resonance/core/routes/app_pages.dart';
import 'package:resonance/core/theme/app_theme.dart';
import 'package:resonance/l10n/app_localizations.dart';

class ResonanceApp extends StatelessWidget {
  const ResonanceApp({super.key, this.initialRoute = AppPages.initial});

  /// Testlerde belirli bir sayfadan başlamak için.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
