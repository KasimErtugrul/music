import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/utils/locale_sorter.dart';

List<String> sorted(List<String> input) =>
    LocaleSorter.sortedBy<String>(input, (s) => s);

void main() {
  group('sıralama', () {
    test('Türkçe alfabe sırası: c < ç, o < ö, s < ş, u < ü', () {
      expect(
        sorted(<String>[
          'Zeki', 'Çiğdem', 'Ceren', 'Şule', 'Sema', 'Ömer', 'Oya', 'Ulaş',
          'Ümit', //
        ]),
        <String>[
          'Ceren', 'Çiğdem', 'Oya', 'Ömer', 'Sema', 'Şule', 'Ulaş', 'Ümit',
          'Zeki', //
        ],
      );
    });

    test('ğ g\'den sonra, h\'den önce gelir', () {
      expect(
        sorted(<String>['Hasan', 'Ğ-test', 'Gül', 'Fatma']),
        <String>['Fatma', 'Gül', 'Ğ-test', 'Hasan'],
      );
    });

    test('ı, i\'den önce gelir; I→ı ve İ→i', () {
      expect(
        sorted(<String>['ilk', 'ışık', 'İstanbul', 'Irmak']),
        <String>['Irmak', 'ışık', 'ilk', 'İstanbul'],
      );
    });

    test('rakam ve semboller harflerden önce, Latin olmayan yazılar sonda', () {
      expect(
        sorted(<String>['Zebra', 'Привет', '99 Luftballons', '(Intro)', 'Ada']),
        <String>['(Intro)', '99 Luftballons', 'Ada', 'Zebra', 'Привет'],
      );
    });

    test('rakamlar sayı değerine değil karakter sırasına göre', () {
      expect(sorted(<String>['10', '2', '1']), <String>['1', '10', '2']);
    });

    test('büyük/küçük harf birincil sırayı etkilemez; eşitlikte küçük önce', () {
      expect(sorted(<String>['b', 'A', 'a', 'B']), <String>['a', 'A', 'b', 'B']);
      expect(sorted(<String>['ada', 'Bora', 'Çağla']),
          <String>['ada', 'Bora', 'Çağla']);
    });

    test('aksanlı Latin harfleri temel harfe katlanır; Türkçe harfler katlanmaz',
        () {
      // é → e: "Éclair", "Eda" ile "Ezgi" arasında.
      expect(
        sorted(<String>['Ezgi', 'Éclair', 'Eda']),
        <String>['Éclair', 'Eda', 'Ezgi'],
      );
      // ö katlanmaz: "Oya" < "Ömer" < "Pelin".
      expect(
        sorted(<String>['Pelin', 'Ömer', 'Oya']),
        <String>['Oya', 'Ömer', 'Pelin'],
      );
    });

    test('azalan sıralama bilinenleri tersler', () {
      expect(
        LocaleSorter.sortedBy<String>(
          <String>['Ada', 'Çiçek', 'Bora'],
          (s) => s,
          descending: true,
        ),
        <String>['Çiçek', 'Bora', 'Ada'],
      );
    });

    test('compare işareti tutarlı', () {
      expect(LocaleSorter.compare('Çay', 'Dam'), lessThan(0));
      expect(LocaleSorter.compare('Dam', 'Çay'), greaterThan(0));
      expect(LocaleSorter.compare('aynı', 'aynı'), 0);
    });
  });

  group('indeks harfi', () {
    test('Türkçe harfler doğru büyütülür', () {
      expect(LocaleSorter.indexLetter('ışık'), 'I');
      expect(LocaleSorter.indexLetter('Irmak'), 'I');
      expect(LocaleSorter.indexLetter('istanbul'), 'İ');
      expect(LocaleSorter.indexLetter('İzmir'), 'İ');
      expect(LocaleSorter.indexLetter('çay'), 'Ç');
      expect(LocaleSorter.indexLetter('şarkı'), 'Ş');
      expect(LocaleSorter.indexLetter('ümit'), 'Ü');
      expect(LocaleSorter.indexLetter('ğ'), 'Ğ');
    });

    test('aksanlı harf temel harfe, rakam/sembol # ve diğer yazı …', () {
      expect(LocaleSorter.indexLetter('Äpfel'), 'A');
      expect(LocaleSorter.indexLetter('1990'), '#');
      expect(LocaleSorter.indexLetter('(Intro)'), '#');
      expect(LocaleSorter.indexLetter(''), '#');
      expect(LocaleSorter.indexLetter('Привет'), '…');
    });

    test('indexLetters çubuk sırası sıralama düzeniyle aynı', () {
      final letters = LocaleSorter.indexLetters;
      expect(letters.first, '#');
      expect(letters.last, '…');
      expect(letters.indexOf('Ç'), letters.indexOf('C') + 1);
      expect(letters.indexOf('I') + 1, letters.indexOf('İ'));
      expect(letters.length, 34);
    });

    test('sıralı listede indeks harfleri bitişik gruplar oluşturur', () {
      final list = sorted(<String>[
        'Zeki', 'ışık', 'Çay', 'ilk', '5', 'Ada', 'Ömer', 'Привет', 'İz', 'Cem',
      ]);
      final order = LocaleSorter.indexLetters;
      var last = -1;
      for (final item in list) {
        final pos = order.indexOf(LocaleSorter.indexLetter(item));
        expect(pos, greaterThanOrEqualTo(last), reason: item);
        last = pos;
      }
    });
  });

  group('arama anahtarı', () {
    test('Türkçe harfler ve büyük/küçük harf katlanır', () {
      expect(LocaleSorter.searchKey('ŞARKI'), 'sarki');
      expect(LocaleSorter.searchKey('Şarkı'), 'sarki');
      expect(LocaleSorter.searchKey('Işık'), 'isik');
      expect(LocaleSorter.searchKey('İSTANBUL'), 'istanbul');
      expect(LocaleSorter.searchKey('Çöğüş'), 'cogus');
    });

    test('aksanlar katlanır', () {
      expect(LocaleSorter.searchKey('Café Ñandú'), 'cafe nandu');
    });
  });

  test('lowerCase Türkçe kurallarını uygular', () {
    expect(LocaleSorter.lowerCase('ISPARTA İZMİR'), 'ısparta izmir');
  });
}
