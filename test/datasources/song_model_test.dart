import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/models/song_model.dart';

void main() {
  group('SongModel.normalizeTag', () {
    test('null, boş ve <unknown> -> null', () {
      expect(SongModel.normalizeTag(null), isNull);
      expect(SongModel.normalizeTag('   '), isNull);
      expect(SongModel.normalizeTag('<unknown>'), isNull);
    });

    test('baştaki UTF-8 BOM temizlenir', () {
      expect(SongModel.normalizeTag('\uFEFFGöçmen Kızı'), 'Göçmen Kızı');
      expect(SongModel.normalizeTag('\uFEFF'), isNull);
    });

    test('Türkçe karakterler korunur, kenar boşlukları kırpılır', () {
      expect(SongModel.normalizeTag(' Çığlık Şarkısı '), 'Çığlık Şarkısı');
    });
  });

  group('SongModel.fromMap', () {
    test('tüm alanları eşler', () {
      final song = SongModel.fromMap(<Object?, Object?>{
        'id': 42,
        'uri': 'content://media/external/audio/media/42',
        'path': '/storage/emulated/0/Music/a.mp3',
        'title': 'Gün Batımı',
        'artist': 'Örnek Sanatçı',
        'album': 'İlk Albüm',
        'genre': 'Pop',
        'albumId': 7,
        'artistId': 9,
        'durationMs': 183000,
        'dateAddedSec': 1700000000,
        'sizeBytes': 4200000,
      });
      expect(song.id, 42);
      expect(song.title, 'Gün Batımı');
      expect(song.artist, 'Örnek Sanatçı');
      expect(song.albumId, 7);
      expect(song.duration, const Duration(minutes: 3, seconds: 3));
      expect(song.dateAdded,
          DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    });

    test('başlık yoksa dosya adından (uzantısız) türetilir', () {
      final song = SongModel.fromMap(<Object?, Object?>{
        'id': 1,
        'uri': 'content://x/1',
        'title': null,
        'displayName': 'kayit_01.m4a',
      });
      expect(song.title, 'kayit_01');
    });

    test('<unknown> sanatçı/albüm null olur; eksik sayılar varsayılan', () {
      final song = SongModel.fromMap(<Object?, Object?>{
        'id': 1,
        'uri': 'content://x/1',
        'title': 'T',
        'artist': '<unknown>',
        'album': '<unknown>',
      });
      expect(song.artist, isNull);
      expect(song.album, isNull);
      expect(song.durationMs, 0);
      expect(song.sizeBytes, 0);
      expect(song.dateAdded, isNull);
    });
  });

  test('eşitlik id + yol ile belirlenir', () {
    SongModel make(int id, String path) => SongModel(
          id: id,
          uri: 'content://x/$id',
          path: path,
          title: 'T',
          durationMs: 1,
          sizeBytes: 1,
        );
    expect(make(1, '/a'), make(1, '/a'));
    expect(make(1, '/a') == make(1, '/b'), isFalse);
    expect(make(1, '/a') == make(2, '/a'), isFalse);
  });
}
