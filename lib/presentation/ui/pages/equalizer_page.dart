import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<EqualizerController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.equalizerTitle),
        actions: [
          Obx(() => Switch(
                value: ctrl.isEnabled.value,
                onChanged: ctrl.toggleEnabled,
              )),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        
        if (ctrl.bands.isEmpty) {
          return Center(child: Text(l10n.equalizerNoBands));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Preset Seçici (Hazır + Özel)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: l10n.equalizerPresets,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          // Hazır Presetler
                          ...ctrl.builtInPresets.map((p) {
                            final label = switch (p.id) {
                              'flat' => l10n.eqPresetFlat,
                              'rock' => l10n.eqPresetRock,
                              'pop' => l10n.eqPresetPop,
                              'jazz' => l10n.eqPresetJazz,
                              'classical' => l10n.eqPresetClassical,
                              'bass' => l10n.eqPresetBass,
                              'treble' => l10n.eqPresetTreble,
                              'vocal' => l10n.eqPresetVocal,
                              _ => p.id,
                            };
                            return DropdownMenuItem(
                              value: 'builtin_${p.id}',
                              child: Text('${l10n.eqGroupBuiltIn} • $label'),
                            );
                          }),
                          // Özel Presetler
                          ...ctrl.presets.map((p) {
                            return DropdownMenuItem(
                              value: 'custom_${p.id}',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${l10n.eqGroupCustom} • ${p.name}'),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => ctrl.deletePreset(p.id),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          if (val.startsWith('builtin_')) {
                            final id = val.replaceFirst('builtin_', '');
                            final preset = ctrl.builtInPresets.firstWhere((p) => p.id == id);
                            ctrl.applyBuiltInPreset(preset);
                          } else {
                            final id = int.parse(val.replaceFirst('custom_', ''));
                            final preset = ctrl.presets.firstWhere((p) => p.id == id);
                            ctrl.applyPreset(preset);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.save),
                      tooltip: l10n.equalizerSavePreset,
                      onPressed: () => _showSaveDialog(context, ctrl, l10n),
                    ),
                  ],
                ),
              ),
              
              // Dikey Sliderlar
              SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: ctrl.bands.asMap().entries.map((entry) {
                      final index = entry.key;
                      final band = entry.value;
                      return Column(
                        children: [
                          Text('${band.gain.toStringAsFixed(1)} dB', style: theme.textTheme.labelSmall),
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: band.gain.clamp(ctrl.minDecibels, ctrl.maxDecibels),
                                min: ctrl.minDecibels,
                                max: ctrl.maxDecibels,
                                onChanged: ctrl.isEnabled.value ? (v) => ctrl.updateBand(index, v) : null,
                              ),
                            ),
                          ),
                          Text('${band.centerFrequency.round()} Hz', style: theme.textTheme.labelSmall),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Divider(),

              // Loudness Enhancer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.loudnessEnhancer, style: theme.textTheme.titleMedium),
                    Row(
                      children: [
                        const Icon(Icons.volume_up, size: 20),
                        Expanded(
                          child: Slider(
                            // Görev 2.3 birim düzeltmesi: değer artık doğrudan
                            // dB cinsindendir (0-15 dB). Eski kod kaydırıcıyı
                            // mB varsayıp /100 ile gösteriyordu; oysa
                            // just_audio Dart tarafında dB bekliyor, Android'e
                            // Java katmanı x100 ile milibele çeviriyor. Sonuç:
                            // "15 dB" diye gösterilen değer ~1500 dB'lik
                            // anlamsız bir kazanca dönüşüyordu.
                            value: ctrl.loudnessGain.value.clamp(0.0, 15.0),
                            min: 0,
                            max: 15,
                            divisions: 30,
                            label: '${ctrl.loudnessGain.value.toStringAsFixed(1)} dB',
                            onChanged: ctrl.isEnabled.value ? (v) => ctrl.setLoudness(v) : null,
                          ),
                        ),
                        Text('${ctrl.loudnessGain.value.toStringAsFixed(1)} dB'),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showSaveDialog(BuildContext context, EqualizerController ctrl, AppLocalizations l10n) async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.equalizerSavePreset),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: l10n.equalizerPresetName),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ctrl.savePreset(name);
    }
  }
}
