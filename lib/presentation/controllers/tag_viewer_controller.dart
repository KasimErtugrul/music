import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/models/tag_model.dart';
import 'package:resonance/data/repositories/tag_editor_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';

class TagViewerController extends GetxController {
  final TagEditorRepository _repo;
  TagViewerController(this._repo);

  final song = Rxn<SongModel>();
  final tag = Rxn<TagModel>();
  final isLoading = true.obs;
  final errorMsg = Rxn<String>();

  Future<void> load(SongModel targetSong, AppLocalizations l10n) async {
    song.value = targetSong;
    isLoading.value = true;
    errorMsg.value = null;
    try {
      tag.value = await _repo.readTags(targetSong.path);
    } catch (_) {
      errorMsg.value = l10n.tagReadError;
    } finally {
      isLoading.value = false;
    }
  }
}