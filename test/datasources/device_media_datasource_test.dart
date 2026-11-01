import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/errors/app_exception.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';

/// Yalnızca B uygulamasını (MethodChannel) test eder. A (eklenti) uygulaması
/// platform arayüzü gerektirdiği için burada test edilmez; cihazda denenir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MediaStoreChannelDataSource.channelName);
  late MediaStoreChannelDataSource dataSource;

  setUp(() => dataSource = MediaStoreChannelDataSource());

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mock(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  test('querySongs kanal haritalarını SongModel listesine çevirir', () async {
    mock((call) async {
      expect(call.method, 'querySongs');
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'uri': 'content://media/external/audio/media/1',
          'path': '/music/a.mp3',
          'title': 'Şarkı',
          'artist': '<unknown>',
          'durationMs': 1000,
        },
      ];
    });
    final songs = await dataSource.querySongs();
    expect(songs, hasLength(1));
    expect(songs.single.title, 'Şarkı');
    expect(songs.single.artist, isNull);
  });

  test('null sonuç boş liste olur', () async {
    mock((call) async => null);
    expect(await dataSource.querySongs(), isEmpty);
  });

  test('platform hatası AppException(mediaQueryFailed) olur', () async {
    mock((call) async => throw PlatformException(code: 'media_store_error'));
    expect(
      dataSource.querySongs(),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.mediaQueryFailed,
        ),
      ),
    );
  });

  test('queryArtwork id ve boyutu iletir; hata null döndürür', () async {
    mock((call) async {
      expect(call.method, 'queryArtwork');
      expect(call.arguments, <String, Object>{'id': 5, 'size': 96});
      return Uint8List.fromList(<int>[1, 2, 3]);
    });
    expect(await dataSource.queryArtwork(5, size: 96), isNotNull);

    mock((call) async => throw PlatformException(code: 'media_store_error'));
    expect(await dataSource.queryArtwork(5, size: 96), isNull);
  });

  group('Gün 17.7: yol bazlı tekilleştirme', () {
    Map<String, Object?> row(int id, String path, {String? title}) =>
        <String, Object?>{
          'id': id,
          'uri': 'content://media/external/audio/media/$id',
          'path': path,
          'title': title ?? 'Şarkı $id',
          'durationMs': 1000,
        };

    test(
      'aynı yol için en güncel kayıt (en büyük id) kazanır, sıra korunur',
      () async {
        // Kullanıcı senaryosu: MediaStore aynı dosyayı iki _id ile döndürdü;
        // şarkı kasadayken yol filtresi ikisini de saklıyordu, kasadan
        // çıkınca iki kopya birden görünüyordu.
        mock(
          (call) async => <Map<String, Object?>>[
            row(7, '/music/a.mp3', title: 'Eski kayıt'),
            row(3, '/music/b.mp3'),
            row(9, '/music/a.mp3', title: 'Taze kayıt'),
          ],
        );
        final songs = await dataSource.querySongs();

        expect(songs, hasLength(2));
        expect(songs[0].id, 9);
        expect(songs[0].title, 'Taze kayıt');
        expect(songs[0].path, '/music/a.mp3');
        expect(songs[1].id, 3);
      },
    );

    test('farklı yollar ayrı dosyalardır ve korunur', () async {
      mock(
        (call) async => <Map<String, Object?>>[
          row(1, '/music/a.mp3'),
          row(2, '/music/copy/a.mp3'),
        ],
      );
      final songs = await dataSource.querySongs();
      expect(songs, hasLength(2));
      expect(songs.map((s) => s.id), [1, 2]);
    });

    test('kopya yoksa girdi listesi olduğu gibi döner', () async {
      final input = <Map<String, Object?>>[
        row(1, '/music/a.mp3'),
        row(2, '/music/b.mp3'),
      ];
      mock((call) async => input);
      final songs = await dataSource.querySongs();
      expect(songs, hasLength(2));
    });

    test('tek satır ve boş liste değişmez', () async {
      mock((call) async => <Map<String, Object?>>[row(1, '/music/a.mp3')]);
      expect((await dataSource.querySongs()), hasLength(1));

      mock((call) async => null);
      expect(await dataSource.querySongs(), isEmpty);
    });
  });
}
