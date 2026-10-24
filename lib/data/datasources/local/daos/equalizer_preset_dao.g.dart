// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equalizer_preset_dao.dart';

// ignore_for_file: type=lint
mixin _$EqualizerPresetDaoMixin on DatabaseAccessor<AppDatabase> {
  $EqualizerPresetsTable get equalizerPresets =>
      attachedDatabase.equalizerPresets;
  EqualizerPresetDaoManager get managers => EqualizerPresetDaoManager(this);
}

class EqualizerPresetDaoManager {
  final _$EqualizerPresetDaoMixin _db;
  EqualizerPresetDaoManager(this._db);
  $$EqualizerPresetsTableTableManager get equalizerPresets =>
      $$EqualizerPresetsTableTableManager(
        _db.attachedDatabase,
        _db.equalizerPresets,
      );
}
