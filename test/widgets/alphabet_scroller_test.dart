// AlphabetScroller sözleşme testleri.
//
// Kilitlenen davranışlar:
// * ÖLÇÜ TARAMASI: şerit 11 farklı yükseklikte (120-800dp) hiçbir
//   koşulda RenderFlex taşması ÜRETMEZ. Bu test, «overflowed by
//   2.0 pixels» hatasını yaşayan kutu/çerçeve yükseklik hatasının
//   kalıcı regresyon kilididir — eski kod bu taramada başarısızdı.
// * Harfe dokunmak geri çağrıyı o harfle tetikler.
// * Kütüphanede olmayan harf, sıradaki ilk mevcut harfe iner
//   (C yok → M'e iner; «ölü» dokunuş olmaz).
// * Dikey sürükleme harf seçer (drag ile hızlı atlama).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/presentation/ui/widgets/alphabet_scroller.dart';

const Map<String, int> _offsets = {'A': 0, 'B': 5, 'M': 12, 'Z': 30};

void main() {
  String? lastLetter;

  Future<void> pumpScroller(WidgetTester tester, double height) async {
    lastLetter = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 40,
              height: height,
              child: AlphabetScroller(
                offsets: _offsets,
                onLetterSelected: (letter) => lastLetter = letter,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ölçü taraması: her yükseklikte layout taşmaz', (tester) async {
    // 120/200: FittedBox zorunlu kısa alanlar · 529-531: sığma/sığmama
    // sınırı (slot = 16 kepenk noktası) · 543: kullanıcının ekranındaki
    // kritik değer · 800: bol alan.
    const heights = <double>[
      120,
      200,
      300,
      400,
      500,
      529,
      530,
      531,
      543,
      600,
      800,
    ];
    for (final h in heights) {
      await pumpScroller(tester, h);
      expect(
        tester.takeException(),
        isNull,
        reason: 'yükseklik $h dp iken layout taşmalı DEĞİL',
      );
    }
  });

  testWidgets('harfe dokununca geri çağrı o harfle tetiklenir', (tester) async {
    await pumpScroller(tester, 543);

    await tester.tap(find.text('B'));
    expect(lastLetter, 'B');
  });

  testWidgets('kütüphanede olmayan harf sıradaki mevcut harfe iner', (
    tester,
  ) async {
    await pumpScroller(tester, 543);

    // C kütüphanede yok: C'den sonraki ilk mevcut harf M.
    await tester.tap(find.text('C'));
    expect(lastLetter, 'M');
  });

  testWidgets('dikey sürükleme harf seçer', (tester) async {
    await pumpScroller(tester, 543);

    // tester.drag: down → kademeli move → up düzenini std. yürütür.
    await tester.drag(
      find.text('A'),
      const Offset(0, 120),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(lastLetter, isNotNull);
  });
}
