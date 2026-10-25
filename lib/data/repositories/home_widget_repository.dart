import 'package:resonance/data/datasources/home_widget_datasource.dart';

abstract class HomeWidgetRepository {
  Future<void> updateWidget({
    required String title,
    required String artist,
    required bool isPlaying,
    required bool isTransparent,
  });
}

class HomeWidgetRepositoryImpl implements HomeWidgetRepository {
  final HomeWidgetDatasource _datasource;
  HomeWidgetRepositoryImpl(this._datasource);

  @override
  Future<void> updateWidget({
    required String title,
    required String artist,
    required bool isPlaying,
    required bool isTransparent,
  }) async {
    await _datasource.saveData(
      title: title,
      artist: artist,
      isPlaying: isPlaying,
      isTransparent: isTransparent,
    );
    await _datasource.updateWidget();
  }
}