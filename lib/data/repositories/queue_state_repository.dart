import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/queue_state_dao.dart';
import 'package:resonance/data/models/queue_state_model.dart';

abstract class QueueStateRepository {
  Future<void> saveState(QueueStateModel state);
  Future<QueueStateModel?> loadState();
  Future<void> clearState();
}

class QueueStateRepositoryImpl implements QueueStateRepository {
  QueueStateRepositoryImpl(this._dao);
  final QueueStateDao _dao;

  @override
  Future<void> saveState(QueueStateModel state) async {
    await _dao.saveState(
      QueueStatesCompanion.insert(
        id: const Value(1),
        songUris: jsonEncode(state.songUris),
        currentIndex: state.currentIndex,
        positionMs: state.position.inMilliseconds,
        shuffleEnabled: state.shuffleEnabled,
        repeatMode: state.repeatMode.index,
        shuffleOrder: Value(
          state.shuffleOrder != null ? jsonEncode(state.shuffleOrder) : null,
        ),
      ),
    );
  }

  @override
  Future<QueueStateModel?> loadState() async {
    final row = await _dao.loadState();
    if (row == null) return null;

    return QueueStateModel(
      songUris: (jsonDecode(row.songUris) as List).cast<String>(),
      currentIndex: row.currentIndex,
      position: Duration(milliseconds: row.positionMs),
      shuffleEnabled: row.shuffleEnabled,
      repeatMode: AudioServiceRepeatMode.values[
          row.repeatMode.clamp(0, AudioServiceRepeatMode.values.length - 1)
      ],
      shuffleOrder: row.shuffleOrder != null
          ? (jsonDecode(row.shuffleOrder!) as List).cast<int>()
          : null,
    );
  }

  @override
  Future<void> clearState() => _dao.clearState();
}