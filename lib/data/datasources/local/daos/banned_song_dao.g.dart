// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banned_song_dao.dart';

// ignore_for_file: type=lint
mixin _$BannedSongDaoMixin on DatabaseAccessor<AppDatabase> {
  $BannedSongsTable get bannedSongs => attachedDatabase.bannedSongs;
  BannedSongDaoManager get managers => BannedSongDaoManager(this);
}

class BannedSongDaoManager {
  final _$BannedSongDaoMixin _db;
  BannedSongDaoManager(this._db);
  $$BannedSongsTableTableManager get bannedSongs =>
      $$BannedSongsTableTableManager(_db.attachedDatabase, _db.bannedSongs);
}
