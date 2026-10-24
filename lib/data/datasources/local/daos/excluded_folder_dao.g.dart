// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'excluded_folder_dao.dart';

// ignore_for_file: type=lint
mixin _$ExcludedFolderDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExcludedFoldersTable get excludedFolders => attachedDatabase.excludedFolders;
  ExcludedFolderDaoManager get managers => ExcludedFolderDaoManager(this);
}

class ExcludedFolderDaoManager {
  final _$ExcludedFolderDaoMixin _db;
  ExcludedFolderDaoManager(this._db);
  $$ExcludedFoldersTableTableManager get excludedFolders =>
      $$ExcludedFoldersTableTableManager(
        _db.attachedDatabase,
        _db.excludedFolders,
      );
}
