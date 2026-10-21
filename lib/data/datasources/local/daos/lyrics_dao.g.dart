// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_dao.dart';

// ignore_for_file: type=lint
mixin _$LyricsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LyricsTable get lyrics => attachedDatabase.lyrics;
  LyricsDaoManager get managers => LyricsDaoManager(this);
}

class LyricsDaoManager {
  final _$LyricsDaoMixin _db;
  LyricsDaoManager(this._db);
  $$LyricsTableTableManager get lyrics =>
      $$LyricsTableTableManager(_db.attachedDatabase, _db.lyrics);
}
