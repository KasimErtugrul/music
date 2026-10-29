import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/audio_format_datasource.dart';
import 'package:resonance/data/models/audio_format_info.dart';

void main() {
  group('AudioFormatInfo.label', () {
    test('kayıpsız tam rozet üretir', () {
      const info = AudioFormatInfo(
        codec: 'FLAC',
        sampleRate: 44100,
        bitsPerSample: 16,
        bitrateKbps: 927,
        lossless: true,
      );
      expect(info.label, 'FLAC · 44.1 kHz · 16 bit · 927 kbps');
    });

    test('kayıplı codec bit derinliğini göstermez', () {
      const info = AudioFormatInfo(
        codec: 'MP3',
        sampleRate: 44100,
        bitrateKbps: 320,
      );
      expect(info.label, 'MP3 · 44.1 kHz · 320 kbps');
    });

    test('tam bölünen hızlar ondalıksız yazılır', () {
      const info = AudioFormatInfo(codec: 'FLAC', sampleRate: 48000, lossless: true, bitsPerSample: 24);
      expect(info.label, 'FLAC · 48 kHz · 24 bit');
      const hiRes = AudioFormatInfo(codec: 'FLAC', sampleRate: 96000, lossless: true, bitsPerSample: 24);
      expect(hiRes.label, 'FLAC · 96 kHz · 24 bit');
    });

    test('tek parça kalırsa rozet üretilmez', () {
      const info = AudioFormatInfo(codec: 'AAC');
      expect(info.label, isNull);
    });
  });

  group('parseFlac', () {
    Uint8List flac({
      int sampleRate = 44100,
      int channels = 2,
      int bits = 16,
    }) {
      final b = BytesBuilder();
      b.add(ascii.encode('fLaC'));
      b.addByte(0x00); // son blok değil, tip 0 (STREAMINFO)
      b.add([0x00, 0x00, 0x22]); // 34 bayt
      b.add(Uint8List(10)); // block/frame boyutları
      final srHi = sampleRate >> 12;
      final srMid = (sampleRate >> 4) & 0xFF;
      final srLo = sampleRate & 0xF;
      b.add([srHi, srMid]);
      b.add([(srLo << 4) | ((channels - 1) << 1) | ((bits - 1) >> 4)]);
      b.add([((bits - 1) & 0x0F) << 4]);
      b.add(Uint8List(20)); // toplam örnek + md5
      return b.toBytes();
    }

    test('CD kalitesi FLAC doğru çözümlenir', () {
      final info = AudioFormatDatasource.parseFlac(flac());
      expect(info, isNotNull);
      expect(info!.codec, 'FLAC');
      expect(info.sampleRate, 44100);
      expect(info.bitsPerSample, 16);
      expect(info.lossless, isTrue);
    });

    test('Hi-Res FLAC (96k/24bit) doğru çözümlenir', () {
      final info = AudioFormatDatasource.parseFlac(flac(sampleRate: 96000, bits: 24));
      expect(info!.sampleRate, 96000);
      expect(info.bitsPerSample, 24);
    });

    test('yanlış magic null döner', () {
      expect(AudioFormatDatasource.parseFlac(Uint8List(64)), isNull);
    });
  });

  group('parseWav', () {
    Uint8List wav({int sampleRate = 48000, int bits = 24, int fmt = 1}) {
      Uint8List le16(int v) => Uint8List.fromList([v & 0xFF, (v >> 8) & 0xFF]);
      Uint8List le32(int v) => Uint8List.fromList([
            v & 0xFF,
            (v >> 8) & 0xFF,
            (v >> 16) & 0xFF,
            (v >> 24) & 0xFF,
          ]);
      final b = BytesBuilder();
      b.add(ascii.encode('RIFF'));
      b.add(le32(36));
      b.add(ascii.encode('WAVE'));
      b.add(ascii.encode('fmt '));
      b.add(le32(16));
      b.add(le16(fmt));
      b.add(le16(2)); // stereo
      b.add(le32(sampleRate));
      b.add(le32(sampleRate * 4));
      b.add(le16(4));
      b.add(le16(bits));
      b.add(ascii.encode('data'));
      b.add(le32(0));
      return b.toBytes();
    }

    test('PCM 48k/24bit çözümlenir', () {
      final info = AudioFormatDatasource.parseWav(wav());
      expect(info!.codec, 'WAV');
      expect(info.sampleRate, 48000);
      expect(info.bitsPerSample, 24);
      expect(info.lossless, isTrue);
    });

    test('IEEE float format etiketi değişir', () {
      final info = AudioFormatDatasource.parseWav(wav(fmt: 3));
      expect(info!.codec, 'WAV Float');
      expect(info.lossless, isTrue);
    });
  });

  group('parseOgg', () {
    Uint8List oggOpus({int inputRate = 48000}) {
      final b = BytesBuilder();
      b.add(ascii.encode('OggS'));
      b.addByte(0); // version
      b.addByte(0x02); // BOS
      b.add(Uint8List(8)); // granule
      b.add(Uint8List(4)); // serial
      b.add(Uint8List(4)); // seq
      b.add(Uint8List(4)); // crc
      b.addByte(1); // segment sayısı
      b.addByte(19); // OpusHead 19 bayt
      b.add(ascii.encode('OpusHead'));
      b.addByte(1); // version
      b.addByte(2); // channels
      b.add([0, 0]); // pre-skip
      b.add(Uint8List.fromList([
        inputRate & 0xFF,
        (inputRate >> 8) & 0xFF,
        (inputRate >> 16) & 0xFF,
        (inputRate >> 24) & 0xFF,
      ]));
      b.add([0, 0]); // output gain
      b.addByte(0); // mapping family
      return b.toBytes();
    }

    test('OpusHead giriş hızı okunur', () {
      final info = AudioFormatDatasource.parseOgg(oggOpus());
      expect(info!.codec, 'Opus');
      expect(info.sampleRate, 48000);
      expect(info.lossless, isFalse);
    });

    test('Vorbis id header 58 baytlık minimal sayfada okunur', () {
      // Gerçek Vorbis ilk sayfası 28 + 30 = 58 bayttır; alt sınır
      // kontrolünün (27 bayt) bu tamponu kabul ettiğini garanti eder.
      final b = BytesBuilder();
      b.add(ascii.encode('OggS'));
      b.addByte(0); // version
      b.addByte(0x02); // BOS
      b.add(Uint8List(8)); // granule
      b.add(Uint8List(4)); // serial
      b.add(Uint8List(4)); // seq
      b.add(Uint8List(4)); // crc
      b.addByte(1); // segment sayısı
      b.addByte(30); // id header 30 bayt
      b.addByte(0x01); // paket tipi
      b.add(ascii.encode('vorbis'));
      b.add(Uint8List(4)); // codec version
      b.addByte(2); // channels
      const sampleRate = 44100;
      b.add(Uint8List.fromList([
        sampleRate & 0xFF,
        (sampleRate >> 8) & 0xFF,
        (sampleRate >> 16) & 0xFF,
        (sampleRate >> 24) & 0xFF,
      ]));
      b.add(Uint8List(14)); // bit hızları + blok boyutu + framing
      final info = AudioFormatDatasource.parseOgg(b.toBytes());
      expect(info!.codec, 'Vorbis');
      expect(info.sampleRate, 44100);
      expect(info.lossless, isFalse);
    });
  });

  group('parseMp3', () {
    test('MPEG1 Layer III 320 kbps / 44.1 kHz çözümlenir', () {
      final b = BytesBuilder();
      b.add(ascii.encode('ID3'));
      b.add([0x03, 0x00, 0x00]);
      b.add([0, 0, 0, 0]); // tag boyutu 0
      // 0xFB: MPEG1 L3; 0xE0: brIdx 14 (320 kbps) + srIdx 0 (44.1 kHz).
      // Not: 0x90 (brIdx 9) standarda göre 128 kbps'tir; 320 için 0xE0 şart.
      b.add([0xFF, 0xFB, 0xE0, 0x00]);
      b.add(Uint8List(64));
      final info = AudioFormatDatasource.parseMp3(b.toBytes());
      expect(info!.codec, 'MP3');
      expect(info.sampleRate, 44100);
      expect(info.bitrateKbps, 320);
      expect(info.lossless, isFalse);
    });

    test('MPEG2 Layer III düşük hız çözümlenir', () {
      final b = BytesBuilder();
      // 0xFF 0xF3 0x80: MPEG2 L3, brIdx 8 (64 kbps), srIdx 0 (22050)
      b.add([0xFF, 0xF3, 0x80, 0x00]);
      b.add(Uint8List(64));
      final info = AudioFormatDatasource.parseMp3(b.toBytes());
      expect(info!.codec, 'MP3');
      expect(info.sampleRate, 22050);
      expect(info.bitrateKbps, 64);
    });
  });

  group('read (MP4 kutu gezinmesi)', () {
    test('m4a stsd örnekleme girdisi çözümlenir', () async {
      Uint8List be32(int v) => Uint8List.fromList([
            (v >> 24) & 0xFF,
            (v >> 16) & 0xFF,
            (v >> 8) & 0xFF,
            v & 0xFF,
          ]);
      Uint8List box(String type, List<int> body) {
        final b = BytesBuilder();
        b.add(be32(8 + body.length));
        b.add(ascii.encode(type));
        b.add(body);
        return b.toBytes();
      }

      const sampleRate = 44100;
      final entryBody = <int>[
        ...List.filled(6, 0), // reserved
        0, 1, // data reference index
        ...List.filled(8, 0), // reserved
        0, 2, // channels
        0, 16, // sample size
        0, 0, // pre defined
        0, 0, // reserved
        (sampleRate >> 8) & 0xFF, sampleRate & 0xFF, 0, 0, // 16.16 fixed
      ];
      final mp4a = box('mp4a', entryBody);
      final stsdBody = <int>[0, 0, 0, 0, 0, 0, 0, 1, ...mp4a];
      final stsd = box('stsd', stsdBody);
      final stbl = box('stbl', stsd);
      final minf = box('minf', stbl);
      final mdia = box('mdia', minf);
      final trak = box('trak', mdia);
      final moov = box('moov', trak);
      final ftyp = box('ftyp', [...ascii.encode('M4A '), 0, 0, 0, 0]);

      final file = File(
        '${Directory.systemTemp.path}/resonance_fmt_test.m4a',
      );
      await file.writeAsBytes([...ftyp, ...moov]);
      addTearDown(file.delete);

      final info = await AudioFormatDatasource().read(file.path);
      expect(info!.codec, 'AAC');
      expect(info.sampleRate, sampleRate);
      expect(info.lossless, isFalse);
    });

    test('olmayan dosya null döner', () async {
      final info = await AudioFormatDatasource().read('/yok/böyle/dosya.flac');
      expect(info, isNull);
    });
  });
}
