/// Türkçe duyarlı sıralama, indeks harfi ve arama anahtarı üretimi.
///
/// Kural 7: A–Z sıralama tek yerde çözülür. Dart'ın `toLowerCase()` /
/// `compareTo()` işlevleri Türkçe değildir (I→i, İ→i̇ ; ç, ğ, ş sonra gelir),
/// bu yüzden her metin önce "sıralama anahtarı"na çevrilir; anahtarlar düz
/// `String.compareTo` ile karşılaştırılır.
///
/// Sıra: boşluk/noktalama < rakamlar < a b c ç d e f g ğ h ı i j k l m n o ö p
/// q r s ş t u ü v w x y z < diğer yazılar (Kiril, Arap, CJK vb.).
/// Aksanlı Latin harfleri (é, ä, ñ ...) temel harfine katlanır; Türkçe harfler
/// (ç, ğ, ı, ö, ş, ü) ayrı harftir ve katlanmaz.
abstract final class LocaleSorter {
  static const String _lower = 'abcçdefgğhıijklmnoöpqrsştuüvwxyz';
  static const String _upper = 'ABCÇDEFGĞHIİJKLMNOÖPQRSŞTUÜVWXYZ';

  /// Harf ağırlıkları [0x80, 0x9F]; bunun altı sembol/rakam, üstü diğer yazılar.
  static const int _letterBase = 0x80;
  static const int _otherBase = 0xA0;

  /// Hızlı kaydırma çubuğundaki "rakam/sembol" ve "diğer yazı" girdileri.
  static const String symbolIndex = '#';
  static const String otherIndex = '…';

  /// Hızlı kaydırma / alfabetik indeks çubuğu için sıralı harf listesi.
  static final List<String> indexLetters = List<String>.unmodifiable(
    <String>[symbolIndex, ..._upper.split(''), otherIndex],
  );

  static final Map<int, int> _letterWeights = <int, int>{
    for (var i = 0; i < _lower.length; i++) _lower.codeUnitAt(i): _letterBase + i,
  };

  /// Türkçe'ye ait olmayan aksanlı Latin harflerinin temel harfe katlanması.
  static final Map<int, int> _fold = () {
    const groups = <String, String>{
      'a': 'áàâäãåāă',
      'c': 'ćč',
      'e': 'éèêëēę',
      'i': 'íìîïī',
      'l': 'ł',
      'n': 'ñń',
      'o': 'óòôõøō',
      's': 'śš',
      'u': 'úùûū',
      'y': 'ýÿ',
      'z': 'žźż',
    };
    final map = <int, int>{};
    groups.forEach((base, chars) {
      for (final r in chars.runes) {
        map[r] = base.codeUnitAt(0);
      }
    });
    return map;
  }();

  /// Arama için Türkçe harfler de ASCII karşılığına indirilir.
  static final Map<int, int> _searchFold = <int, int>{
    'ç'.codeUnitAt(0): 'c'.codeUnitAt(0),
    'ğ'.codeUnitAt(0): 'g'.codeUnitAt(0),
    'ı'.codeUnitAt(0): 'i'.codeUnitAt(0),
    'ö'.codeUnitAt(0): 'o'.codeUnitAt(0),
    'ş'.codeUnitAt(0): 's'.codeUnitAt(0),
    'ü'.codeUnitAt(0): 'u'.codeUnitAt(0),
  };

  /// Türkçe küçük harfe çevirir: I→ı, İ→i.
  static int _lowerRune(int r) {
    if (r == 0x49) return 0x131; // I → ı
    if (r == 0x130) return 0x69; // İ → i
    if (r < 0x80) return (r >= 0x41 && r <= 0x5A) ? r + 0x20 : r;
    return String.fromCharCode(r).toLowerCase().runes.first;
  }

  /// Türkçe kurallarıyla küçük harf (genre anahtarı vb. için).
  static String lowerCase(String text) =>
      String.fromCharCodes(text.runes.map(_lowerRune));

  /// -1: bu karakter anahtara girmez (birleştirici işaret, C1 kontrol).
  static int _weight(int lower) {
    if (lower >= 0x300 && lower <= 0x36F) return -1;
    if (lower >= 0x80 && lower < 0xA0) return -1;
    final folded = _fold[lower] ?? lower;
    return _letterWeights[folded] ?? folded;
  }

  /// Sıralama anahtarı: düz `compareTo` ile Türkçe sıra verir.
  /// Büyük/küçük harf ayrımı yoktur (eşitlik [compare] içinde kırılır).
  static String collationKey(String text) {
    final units = <int>[];
    for (final r in text.runes) {
      final w = _weight(_lowerRune(r));
      if (w >= 0) units.add(w);
    }
    return String.fromCharCodes(units);
  }

  /// İki metni Türkçe sıraya göre karşılaştırır. Anahtarlar eşitse küçük harf
  /// büyük harften önce gelir (a < A).
  static int compare(String a, String b) {
    final c = collationKey(a).compareTo(collationKey(b));
    if (c != 0) return c;
    return b.compareTo(a);
  }

  /// Listeyi Türkçe sıraya göre sıralar; anahtarlar bir kez hesaplanır.
  static List<T> sortedBy<T>(
    Iterable<T> items,
    String Function(T item) text, {
    bool descending = false,
  }) {
    final decorated = <(String, String, T)>[];
    for (final item in items) {
      final t = text(item);
      decorated.add((collationKey(t), t, item));
    }
    decorated.sort((x, y) {
      var c = x.$1.compareTo(y.$1);
      if (c == 0) c = y.$2.compareTo(x.$2);
      return descending ? -c : c;
    });
    return <T>[for (final d in decorated) d.$3];
  }

  /// Hızlı kaydırma harfi: A, B, C, Ç ... Z; rakam/sembol için `#`, Latin
  /// olmayan yazılar için `…`. Sıralama düzeniyle birebir tutarlıdır.
  static String indexLetter(String text) =>
      indexLetterOfKey(collationKey(text));

  /// [collationKey] çıktısından indeks harfi.
  static String indexLetterOfKey(String key) {
    if (key.isEmpty) return symbolIndex;
    final w = key.runes.first;
    if (w < _letterBase) return symbolIndex;
    if (w < _otherBase) return _upper[w - _letterBase];
    return otherIndex;
  }

  /// Arama anahtarı: Türkçe küçük harf + aksan/Türkçe harf katlama.
  /// "Şarkı", "SARKI", "sarki" aynı anahtara iner; "I", "ı", "İ", "i" hepsi `i`.
  static String searchKey(String text) {
    final out = <int>[];
    for (final r in text.runes) {
      var l = _lowerRune(r);
      if (l >= 0x300 && l <= 0x36F) continue;
      l = _fold[l] ?? _searchFold[l] ?? l;
      out.add(l);
    }
    return String.fromCharCodes(out);
  }
}
