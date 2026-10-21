// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_state_dao.dart';

// ignore_for_file: type=lint
mixin _$QueueStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $QueueStatesTable get queueStates => attachedDatabase.queueStates;
  QueueStateDaoManager get managers => QueueStateDaoManager(this);
}

class QueueStateDaoManager {
  final _$QueueStateDaoMixin _db;
  QueueStateDaoManager(this._db);
  $$QueueStatesTableTableManager get queueStates =>
      $$QueueStatesTableTableManager(_db.attachedDatabase, _db.queueStates);
}
