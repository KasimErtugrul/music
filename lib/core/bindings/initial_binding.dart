import 'package:get/get.dart';
import 'package:resonance/data/datasources/metadata_datasource.dart';
import 'package:resonance/data/repositories/tag_editor_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/datasources/local/daos/queue_state_dao.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/bindings/playlist_binding.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/history_controller.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:resonance/presentation/controllers/stats_controller.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/equalizer_datasource.dart';
import 'package:resonance/data/datasources/local/daos/equalizer_preset_dao.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';

import '../../data/datasources/local/daos/custom_theme_dao.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PermissionHelper>(PermissionHelper(), permanent: true);
    Get.lazyPut<PermissionController>(
      () => PermissionController(Get.find<PermissionHelper>()),
      fenix: true,
    );
    Get.lazyPut<DeviceMediaDataSource>(
      () => MediaStoreChannelDataSource(),
      fenix: true,
    );
        Get.lazyPut<LibraryRepository>(
      () => LibraryRepositoryImpl(
        Get.find<DeviceMediaDataSource>(),
        Get.find<PreferencesRepository>(), // YENİ
      ),
      fenix: true,
    );

    // Gün 10: DB, Kuyruk Kalıcılığı
    Get.put<AppDatabase>(AppDatabase.defaults(), permanent: true);
    Get.put<QueueStateDao>(
      Get.find<AppDatabase>().queueStateDao,
      permanent: true,
    );
    Get.put<QueueStateRepository>(
      QueueStateRepositoryImpl(Get.find<QueueStateDao>()),
      permanent: true,
    );

    // Gün 14: Favoriler ve Geçmiş
    Get.put<FavoriteDao>(Get.find<AppDatabase>().favoriteDao, permanent: true);
    Get.put<HistoryDao>(Get.find<AppDatabase>().historyDao, permanent: true);
    Get.put<FavoriteRepository>(
      FavoriteRepositoryImpl(Get.find<FavoriteDao>()),
      permanent: true,
    );
    Get.put<HistoryRepository>(
      HistoryRepositoryImpl(
        Get.find<HistoryDao>(),
        Get.find<LibraryRepository>(),
      ),
      permanent: true,
    );
    Get.put<FavoriteController>(
      FavoriteController(Get.find<FavoriteRepository>()),
      permanent: true,
    );
    Get.put<HistoryController>(
      HistoryController(Get.find<HistoryRepository>()),
      permanent: true,
    );

    // Gün 8: Player
    Get.put<PlayerRepository>(
      PlayerRepositoryImpl(Get.find<ResonanceAudioHandler>()),
      permanent: true,
    );
    Get.put<PlayerController>(
      PlayerController(
        Get.find<PlayerRepository>(),
        Get.find<LibraryRepository>(),
        Get.find<QueueStateRepository>(),
        Get.find<HistoryRepository>(),
      ),
      permanent: true,
    );
    Get.put<StatsRepository>(
      StatsRepositoryImpl(
        Get.find<HistoryDao>(),
        Get.find<LibraryRepository>(),
      ),
      permanent: true,
    );
    Get.put<StatsController>(
      StatsController(Get.find<StatsRepository>()),
      permanent: true,
    );

    Get.put<PlaylistDao>(Get.find<AppDatabase>().playlistDao, permanent: true);
    Get.put<AppSearchController>(
      AppSearchController(Get.find<LibraryRepository>()),
      permanent: true,
    );
    Get.put<CustomThemeDao>(Get.find<AppDatabase>().customThemeDao, permanent: true);
  Get.put<CustomThemeRepository>(
    CustomThemeRepositoryImpl(Get.find<CustomThemeDao>()),
    permanent: true,
  );

   Get.put<EqualizerPresetDao>(Get.find<AppDatabase>().equalizerPresetDao, permanent: true);
    
    Get.put<EqualizerDatasource>(EqualizerDatasource(Get.find<EqualizerPresetDao>()), permanent: true);
    
     Get.put<EqualizerRepository>(
      EqualizerRepositoryImpl(
        Get.find<AudioEffectsDatasource>(), 
        Get.find<EqualizerDatasource>(),
        Get.find<SharedPreferences>(), // EKLENDİ
      ), 
      permanent: true
    );
    
    Get.put<EqualizerController>(
      EqualizerController(Get.find<EqualizerRepository>()),
      permanent: true,
    );

     Get.put<MetadataDatasource>(MetadataDatasource(), permanent: true);
    Get.put<TagEditorRepository>(
      TagEditorRepositoryImpl(Get.find<MetadataDatasource>()),
      permanent: true,
    );
    // Gün 13: Playlist controller'ı HomePage içindeki PlaylistsPage için hemen hazırla
    PlaylistBinding().dependencies();
  }
}
