// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_theme_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomThemeDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomThemesTable get customThemes => attachedDatabase.customThemes;
  CustomThemeDaoManager get managers => CustomThemeDaoManager(this);
}

class CustomThemeDaoManager {
  final _$CustomThemeDaoMixin _db;
  CustomThemeDaoManager(this._db);
  $$CustomThemesTableTableManager get customThemes =>
      $$CustomThemesTableTableManager(_db.attachedDatabase, _db.customThemes);
}
