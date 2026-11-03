import 'dart:async';

import 'package:flutter/material.dart';

/// Kütüphane «Şarkılar» görünümünün sağ kenarındaki alfabe şeridi.
///
/// Eski sürümün iki sorunu vardı:
///  1. FittedBox tüm sütunu mevcut yüksekliğe ölçekleyince harfler
///     küçülüyor, dokunma alanları ~10px'e düşüyor ve «çalışmıyor»
///     hissi veriyordu; ayrıca yalnızca tek tek DOKUNMA vardı, parmağı
///     kaydırma (drag) yoktu.
///  2. Görsel dil zayıftı: yarı saydam kutu, küçük tipografi, ince vurgu.
///
/// Yeni sürüm:
///  • Hem dokunma hem DİKEY SÜRÜKLEME destekler (parmak harflerin
///    üstünde gezinirken liste anlık kayar).
///  • Her harfin dokunma alanı en az 9dp yüksekliktedir; kutu asla
///    küçültülmez (aşırı kısa ekranlarda FittedBox devreye girer).
///  • Kütüphanede olmayan harfe dokunulursa sıradaki İLK mevcut harfe
///    gider — her dokunuş bir sonuç üretir.
///  • Sürükleme sırasında parmağın hizasında yuvarlak bir baloncuğda
///    seçilen harf gösterilir.
///
/// TAŞMA GARANTİSİ (RenderFlex overflow düzeltmesi): kutu çerçevesi
/// 1dp üst + 1dp alt yer yer ve Container kendi yüksekliğinden bu
/// payı DÜŞEREK çocuğa verir. Eski kodda kutu yüksekliği = sütun
/// yüksekliği yapıldığı için iç alan daima 2dp kısa kalıyor ve layout
/// her sayfada «overflowed by 2.0 pixels» hatası fırlatıyordu. Artık:
///  • kutu daima TAM yüksekliği kaplar (height = constraints.maxHeight),
///  • harf sütunu çerçevesiz İÇ yüksekliğe göre hesaplanır
///    (stripHeight ≤ innerHeight, gerçek payla),
///  • iç yükseklik yetmezse sütun FittedBox ile zarifçe küçülür.
/// Böylece taşma mekanik olarak imkânsızdır; ölçü taraması testi
/// (alphabet_scroller_test.dart) bunu 11 farklı yükseklikte kilitler.
class AlphabetScroller extends StatefulWidget {
  const AlphabetScroller({
    super.key,
    required this.offsets,
    required this.onLetterSelected,
  });

  /// Harf → listedeki ilk şarkının satır indeksi.
  final Map<String, int> offsets;
  final ValueChanged<String> onLetterSelected;

  @override
  State<AlphabetScroller> createState() => _AlphabetScrollerState();
}

class _AlphabetScrollerState extends State<AlphabetScroller> {
  /// Kutu çerçevesinin kalınlığı: `Border.all` varsayılanı 1dp.
  static const double _stripBorderWidth = 1.0;

  static const List<String> _alphabet = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'F',
    'G',
    'Ğ',
    'H',
    'I',
    'İ',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'Q',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  static const Duration _bubbleFade = Duration(milliseconds: 120);
  Timer? _bubbleTimer;
  String? _dragLetter;

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  /// Seçilen harf kütüphanede yoksa ALFABEDEKİ sıradaki ilk mevcut harfe
  /// iner; hiçbiri yoksa null. Böylece «ölü» harfe dokunmak boşa gitmez.
  String? _resolve(String letter) {
    if (widget.offsets.containsKey(letter)) return letter;
    final start = _alphabet.indexOf(letter);
    for (var i = start + 1; i < _alphabet.length; i++) {
      if (widget.offsets.containsKey(_alphabet[i])) return _alphabet[i];
    }
    return null;
  }

  void _selectAt(double dy, double slotHeight) {
    var idx = dy ~/ slotHeight;
    if (idx < 0) idx = 0;
    if (idx > _alphabet.length - 1) idx = _alphabet.length - 1;
    final letter = _alphabet[idx];
    final target = _resolve(letter);
    if (target == null) return;
    _bubbleTimer?.cancel();
    setState(() => _dragLetter = letter);
    widget.onLetterSelected(target);
  }

  void _scheduleBubbleClear() {
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _dragLetter = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = _alphabet.length;
        // Her harfe 9-16dp arası eşit slot; normal durumda kutu asla
        // küçültülmez (eski «harfler çalışmıyor» hatasının kökü).
        // Yalnız AŞIRI kısa alanlarda (h < 9dp x 33) FittedBox devreye girer.
        final innerHeight = (constraints.maxHeight - _stripBorderWidth * 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        final slot = (innerHeight / n).clamp(9.0, 16.0).toDouble();
        final stripHeight = slot * n;
        final overflows = stripHeight > innerHeight;
        final fontSize = (slot * 0.62).clamp(8.0, 10.5).toDouble();

        final lettersColumn = Column(
          children: [
            for (var i = 0; i < n; i++)
              SizedBox(
                height: slot,
                width: 26,
                child: Center(
                  child: Text(
                    _alphabet[i],
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.0,
                      fontWeight: _dragLetter == _alphabet[i]
                          ? FontWeight.w800
                          : widget.offsets.containsKey(_alphabet[i])
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _dragLetter == _alphabet[i]
                          ? cs.primary
                          : widget.offsets.containsKey(_alphabet[i])
                          ? cs.onSurface
                          : cs.onSurfaceVariant.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
          ],
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 26,
              // KUTU DAİMA TAM YÜKSEKLİKTE: eskiden sığma durumunda
              // height = stripHeight yapılıyordu; çerçeve bu yüksekliğin
              // içinden yendiği için çocuk 2dp kısa alana sıkışıyordu.
              // Artık kutu tam yükseklikte, sütun iç alanda gerçek payla
              // durur; yetmezse FittedBox küçültür (scaleDown asla
              // büyütmez). topCenter: harfler üstten başlar, dokunma
              // ve baloncuk matematiği (i * slot) bozulmaz.
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _selectAt(d.localPosition.dy, slot),
                onTapUp: (_) => _scheduleBubbleClear(),
                onTapCancel: _scheduleBubbleClear,
                onVerticalDragUpdate: (d) =>
                    _selectAt(d.localPosition.dy, slot),
                onVerticalDragEnd: (_) => _scheduleBubbleClear(),
                onVerticalDragCancel: _scheduleBubbleClear,
                child: overflows
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: lettersColumn,
                      )
                    : lettersColumn,
              ),
            ),
            // Sürükleme baloncuğu: parmağın hizasında, şeridin solunda.
            Positioned(
              right: 34,
              top: _dragLetter == null
                  ? -40.0
                  : ((_alphabet.indexOf(_dragLetter!) * slot).clamp(
                              0.0,
                              stripHeight - 32.0,
                            ) -
                            4)
                        .toDouble(),
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: _bubbleFade,
                  opacity: _dragLetter == null ? 0 : 1,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _dragLetter ?? '',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
