import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_pages.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/pages/splash_page.dart';

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
        // Görev 1.6: Yazı ölçeği (textScale) tüm uygulamaya uygulanır.
        // Gün 3 düzeltmesi (Karar): yorum "sistem ölçeğiyle ÇARPILIR" diyordu
        // ama kod TextScaler.linear(scale) ile SİSTEM ölçeğini eziyordu; artık
        // gerçekten çarpılır ve bileşke değer 0.5–2.0'a kırpılır. 1.00 değeri
        // "sistem ölçeğini aynen devral" anlamına gelir.
        builder: (context, child) {
          final setting = themeCtrl.settings.value.textScale;
          // Builder bağlamı uygulama düzeyi MediaQuery'nin altındadır; buradan
          // okunan ölçekçi sistem erişilebilirlik ölçeğidir (lineer olmayan
          // sistem ölçekleyicilerde de faktör örneklenerek çarpılır).
          final systemScale =
              MediaQuery.of(context).textScaler.scale(10) / 10;
          final combined = (systemScale * setting).clamp(0.5, 2.0).toDouble();
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(combined)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        // Tanımsız bir yol gelirse (ör. dış intent) boş ekran yerine açılış sayfası.
        unknownRoute: GetPage<dynamic>(
          name: '/not-found',
          page: () => const SplashPage(),
        ),
        // initialBinding KALDIRILDI (main.dart'ta var)
      );
    });
  }
}
