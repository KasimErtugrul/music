import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/queue_state_table.dart';

part 'queue_state_dao.g.dart';

@DriftAccessor(tables: [QueueStates])
class QueueStateDao extends DatabaseAccessor<AppDatabase>
    with _$QueueStateDaoMixin {
  QueueStateDao(super.db);

  Future<void> saveState(QueueStatesCompanion state) {
    return into(queueStates).insertOnConflictUpdate(state);
  }

  Future<QueueState?> loadState() {
    return (select(queueStates)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> clearState() => delete(queueStates).go();
}