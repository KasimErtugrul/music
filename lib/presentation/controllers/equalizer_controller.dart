import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/models/equalizer_model.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';

class BuiltInPreset {
  final String id;
  final List<double> curve; // [Bass, Mid, Treble] (-1.0 to 1.0)
  const BuiltInPreset(this.id, this.curve);
}

class EqualizerController extends GetxController {
  final EqualizerRepository _repo;
  EqualizerController(this._repo);

  /// Bulgu 6: kalıcı yazımlar (platform + DB) tek sıradan geçer; her görev
  /// önceki yazım tamamlanmadan başlamaz. Böylece iç içe çağrılarda
  /// saveGains anlık görüntüsü yarışmaz (karışık eğri diske yazılamaz)
  /// ve platform yazımlarının sırası korunur. Hatalı görev zinciri
  /// kırmaz: sıra canlı kalır, hata çağırana yansır.
  Future<void> _writeChain = Future.value();

  Future<void> _enqueueWrite(Future<void> Function() task) {
    final result = _writeChain.then((_) => task());
    _writeChain = result.catchError((Object _) {});
    return result;
  }

  final isLoading = true.obs;
  final isEnabled = false.obs;
  final params = Rxn<AndroidEqualizerParameters>();
  final presets = <EqualizerPresetModel>[].obs;

  /// Manuel loudness hedefi. Görev 2.3 birim düzeltmesi: değer artık
  /// doğrudan dB cinsindendir (eski sürüm mB varsayıp arayüzde /100 ile
  /// gösteriyordu; just_audio dB beklediği için kaydırıcı devasa bir
  /// kazanç uyguluyordu).
  final loudnessGain = 0.0.obs;

  List<AndroidEqualizerBand> get bands => params.value?.bands ?? [];
  double get minDecibels => params.value?.minDecibels ?? -15.0;
  double get maxDecibels => params.value?.maxDecibels ?? 15.0;

  // Hazır preset tanımları
  final List<BuiltInPreset> builtInPresets = const [
    BuiltInPreset('flat', [0.0, 0.0, 0.0]),
    BuiltInPreset('rock', [0.6, -0.1, 0.5]),
    BuiltInPreset('pop', [0.3, 0.4, 0.2]),
    BuiltInPreset('jazz', [0.4, 0.2, 0.3]),
    BuiltInPreset('classical', [0.2, 0.2, 0.3]),
    BuiltInPreset('bass', [1.0, 0.0, 0.0]),
    BuiltInPreset('treble', [0.0, 0.0, 1.0]),
    BuiltInPreset('vocal', [-0.2, 0.8, 0.2]),
  ];

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  /// Gün 1: yedek içe aktarma sonrası kalıcı EQ durumunu (anahtar, bant
  /// kazançları, loudness) yeniden okuyup donanıma uygular. [_init] zaten
  /// kayıtlı değerleri okuyup geri yüklediği için aynı yol izlenir.
  Future<void> reload() => _init();

  Future<void> _init() async {
    isLoading.value = true;
    try {
      isEnabled.value = await _repo.isEnabled();

      // Parametreleri okumak için ekolayzeri geçici etkinleştir
      await _repo.setEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));

      params.value = await _repo.getParameters().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (params.value == null || params.value!.bands.isEmpty) {
        throw Exception('Not supported');
      }

      presets.assignAll(await _repo.getPresets());

      // Görev 2.4: kalıcı bant kazançlarını geri yükle. Bant sayısı cihaza
      // göre değişebileceğinden en fazla yazılan uzunluk uygulanır; fazla
      // değerler yok sayılır.
      final savedGains = _repo.loadGains();
      if (savedGains != null && savedGains.isNotEmpty) {
        final bandList = params.value!.bands;
        for (var i = 0; i < bandList.length && i < savedGains.length; i++) {
          await bandList[i].setGain(savedGains[i]);
        }
        params.refresh();
      }

      // Görev 2.4: kalıcı loudness değerini (dB) geri yükle.
      final savedLoudness = _repo.loadLoudness();
      if (savedLoudness != null) loudnessGain.value = savedLoudness;

      // Görev 2.3: loudness kanalının durumu artık EQ anahtarından
      // bağımsız türetilir. ReplayGain açıksa kanal PlayerController
      // tarafından da kullanılır, açık tutulur; kapalıysa eski davranış
      // korunur (kanal ekolayzer anahtarını izler).
      final replayGainOn =
          Get.find<PreferencesController>().playback.value.replayGain;
      await _repo.setLoudnessEnabled(isEnabled.value || replayGainOn);
      await _repo.setLoudnessGain(loudnessGain.value);

      // Kullanıcının önceki tercihini geri yükle
      await _repo.setEnabled(isEnabled.value);
    } catch (e) {
      params.value = null;
      // Parametre okuma başarısızsa geçici etkinleştirilen ekolayzer
      // donanımda açık kalmasın: kullanıcının kayıtlı tercihi geri yüklenir.
      try {
        await _repo.setEnabled(isEnabled.value);
      } on Object {
        // Geri yükleme de başarısızsa yapılacak başka bir şey yok.
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleEnabled(bool value) async {
    // Get.find eski davranışta da patlayabilirdi; Rx'e dokunmadan ÖNCE
    // okunur ki bağımlılık hatasında anahtar yarım durumda kalmasın.
    final loudnessFollows =
        !Get.find<PreferencesController>().playback.value.replayGain;
    final previous = isEnabled.value;
    isEnabled.value = value;
    try {
      await _repo.setEnabled(value);
      // Görev 2.3: kanallar ayrıldı. ReplayGain kapalıyken eski davranış
      // korunur (loudness kanalı EQ anahtarını izler); açıkken kanalın
      // sahibi ReplayGain'dir ve burada dokunulmaz.
      if (loudnessFollows) {
        await _repo.setLoudnessEnabled(value);
      }
    } on Object {
      // Bulgu 12: optimistik anahtar geri alınır. Watch/akış bu alanı
      // beslemediği için hata durumunda kendiliğinden düzelmez; kalp
      // deseniyle (Bulgu 11) aynı sözleşme: eski değere dön + fırlat.
      isEnabled.value = previous;
      try {
        // Donanımda kısmi yazım ihtimaline karşı önceki tercih
        // best-effort geri yazılır; bu geri yazım da patlarsa Rx
        // zaten doğru değeri gösteriyor, yapılacak başka şey yok.
        await _repo.setEnabled(previous);
        if (loudnessFollows) {
          await _repo.setLoudnessEnabled(previous);
        }
      } on Object {
        // Best-effort.
      }
      rethrow;
    }
  }

  /// Bulgu 6: sürükleme tiki (Slider.onChanged). Sadece DONANIM değerini
  /// günceller (just_audio 0.10.6 setGain yerel değeri senkron günceller:
  /// gainSubject.add; canlı ses/etiket geri bildirimi korunur) ve Rx'i
  /// tazeler. DB'ye (setBandGain/saveGains) DOKUNMAZ: eski kodda her tik
  /// bir saveGains snapshot'ı başlatıyor, iç içe tıklerde görüntü yarışı
  /// karışık eğriyi diske yazabiliyordu. Kalıcılık tek seferlik
  /// [commitBand]'dedir (onChangeEnd).
  void previewBand(int index, double gain) {
    final p = params.value;
    if (p == null || index < 0 || index >= p.bands.length) return;
    unawaited(
      p.bands[index].setGain(gain).catchError((Object _) {
        // Önizleme platform hatası yutulur: yerel değer zaten güncel,
        // kalıcı yazım commitBand'de yeniden denenir.
      }),
    );
    params.refresh();
  }

  /// Bulgu 6: sürükleme bitti (Slider.onChangeEnd). Eski updateBand'in
  /// tam yazım yolu (donanım setGain + setBandGain + saveGains) TEK
  /// SEFERLİK ve yazım kuyruğundan çalışır; saveGains görüntüsü kuyruğun
  /// kendi görevi içinde alındığı için eşzamanlı başka yazımla
  /// serpiştirilemez. Sonuç: diske yalnız son eğri yazılır.
  Future<void> commitBand(int index, double gain) => _enqueueWrite(() async {
        final p = params.value;
        if (p == null || index < 0 || index >= p.bands.length) return;
        await p.bands[index].setGain(gain);
        await _repo.setBandGain(index, gain);
        await _repo.saveGains(p.bands.map((b) => b.gain).toList());
      });

  /// Preset uygulama yolu: bant sırasına göre tam yazım (davranış
  /// eskisiyle aynı); Bulgu 6 ile birlikte yazım kuyruğundan geçer.
  Future<void> updateBand(int index, double gain) => _enqueueWrite(() async {
        if (params.value == null) return;
        await params.value!.bands[index].setGain(gain);
        params.refresh();
        await _repo.setBandGain(index, gain);
        // Görev 2.4: kazanç eğrisini kalıcı hale getir. Preset uygulaması da
        // updateBand üzerinden geçtiği için otomatik olarak kaydedilir.
        await _repo.saveGains(params.value!.bands.map((b) => b.gain).toList());
      });

  Future<void> setLoudness(double gain) async {
    loudnessGain.value = gain;
    await _repo.setLoudnessGain(gain); // birim: dB (görev 2.3 düzeltmesi)
    // Görev 2.4: değeri kalıcı hale getir.
    await _repo.saveLoudness(gain);
  }

  Future<void> applyPreset(EqualizerPresetModel preset) async {
    for (var i = 0; i < bands.length && i < preset.gains.length; i++) {
      await updateBand(i, preset.gains[i]);
    }
  }

  Future<void> applyBuiltInPreset(BuiltInPreset preset) async {
    if (params.value == null) return;

    final newGains = bands.map((band) {
      // Bas (<250Hz), Orta (250-4000Hz), Tiz (>4000Hz)
      double val;
      if (band.centerFrequency < 250) {
        val = preset.curve[0];
      } else if (band.centerFrequency < 4000) {
        val = preset.curve[1];
      } else {
        val = preset.curve[2];
      }

      // -1..1 aralığını cihazın min/max dB değerlerine ölçekle
      if (val > 0) return val * maxDecibels;
      if (val < 0) return val * minDecibels.abs();
      return 0.0;
    }).toList();

    for (var i = 0; i < bands.length; i++) {
      await updateBand(i, newGains[i]);
    }
  }

  Future<void> savePreset(String name) async {
    final currentGains = bands.map((b) => b.gain).toList();
    await _repo.savePreset(name, currentGains);
    presets.assignAll(await _repo.getPresets());
  }

  Future<void> deletePreset(int id) async {
    await _repo.deletePreset(id);
    presets.assignAll(await _repo.getPresets());
  }
}
