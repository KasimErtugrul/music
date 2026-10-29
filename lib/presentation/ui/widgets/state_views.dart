import 'package:flutter/material.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

/// Şartnamedeki boş/hata durumlarının tasarlanmış görünüm modestir.
///
/// Her görünüm gerçek bir konuma bağlanır (sahte simülatör yoktur):
/// - [EmptyLibraryView]   → Ana sayfa (Bölüm 6.4): kütüphane boş
/// - [PermissionDeniedView] → Ana sayfa (Bölüm 6.2): izin yok/rededildi
/// - [NoLyricsView]        → Oynatıcı (Bölüm 6.15): söz gösterimi yok
/// - [NoSearchResultsView] → Arama (Bölüm 6.17): sonuç boş
class EmptyLibraryView extends StatelessWidget {
  const EmptyLibraryView({
    super.key,
    required this.onScan,
    this.onFolders,
  });

  /// Gerçek yeniden tarama eylemi (LibraryController.refresh / rescan).
  final VoidCallback onScan;

  /// Klasör/izin yönetimine gidiş (isteğe bağlı).
  final VoidCallback? onFolders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              base: Icons.library_music,
              badge: Icons.folder_off,
              baseColor: cs.primary,
              badgeColor: cs.error,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.homeEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.homeEmptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 320,
              child: FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.sync, size: 20),
                label: Text(l10n.homeScanNow),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            if (onFolders != null) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: 320,
                child: FilledButton.tonalIcon(
                  onPressed: onFolders,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                  label: Text(l10n.stateFoldersAction),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Tavsiye edilen yol kutusu
            Container(
              width: 320,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.statePathHintTitle,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '/storage/emulated/0/Music',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _FormatBar(),
          ],
        ),
      ),
    );
  }
}

// ========== 6.2 İZİN REDDEDİLDİ ==========

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    super.key,
    required this.onOpenSettings,
    this.onRetry,
  });

  /// Uygulama ayarlarını açar (PermissionController.openSettings).
  final VoidCallback onOpenSettings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cs.onErrorContainer.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gpp_maybe,
                        size: 26, color: cs.onErrorContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.onErrorContainer
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.permissionMediaSpec,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.permissionDeniedTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.permissionDeniedDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onErrorContainer.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_suggest, size: 20),
                  label: Text(l10n.permissionOpenSettingsButton),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: cs.onErrorContainer,
                    foregroundColor: cs.errorContainer,
                  ),
                ),
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onRetry,
                    child: Text(
                      l10n.commonRetry,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ========== 6.15 SÖZ YOK ==========

/// Söz gösterimi bu sürümde kapsam dışı olduğu için görünüm yalnızca
/// bilgilendirir; .lrc içe aktarma düğmesi (tasarımda var) eklenmedi.
class NoLyricsView extends StatelessWidget {
  const NoLyricsView({super.key, required this.song});
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.subtitles_off,
                        size: 28, color: cs.onSecondaryContainer),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.music_off,
                      size: 15, color: cs.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.stateNoLyricsTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.stateNoLyricsMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Aktif parça kartı
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ArtworkImage(
                    songId: song.id >= 0 ? song.id : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        song.artist ?? l10n.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Oynatıcının söz düğmesinden açılacak sheet yardımcısı.
  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => NoLyricsView(song: song),
    );
  }
}

// ========== 6.17 ARAMA SONUCU YOK ==========

class NoSearchResultsView extends StatelessWidget {
  const NoSearchResultsView({
    super.key,
    required this.query,
    required this.onClear,
    required this.suggestions,
    required this.onSuggestion,
  });

  final String query;
  final VoidCallback onClear;

  /// Önerilen terimler (kütüphaneden türetilir: sanatçı adları).
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arama girdisi taklidi (gerçek sorgu metniyle)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 19, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(Icons.close,
                          size: 16, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off, size: 38, color: cs.outline),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.searchEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.searchEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            if (suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.stateSuggestedLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions.take(4))
                    ActionChip(
                      label: Text(s),
                      onPressed: () => onSuggestion(s),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== ORTAK PARÇALAR ==========

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.base,
    required this.badge,
    required this.baseColor,
    required this.badgeColor,
  });

  final IconData base;
  final IconData badge;
  final Color baseColor;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          // Işıma halkası
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      cs.tertiaryContainer.withValues(alpha: 0.25),
                      cs.tertiaryContainer.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(base, size: 32, color: cs.onTertiaryContainer),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(badge, size: 19, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desteklenen çevrimdışı biçim şeridi (Android platformu yerel olarak
/// çözer: FLAC / WAV / MP3 / M4A). Tasarımdaki "Direct Bitstream" iddiası
/// eklenmedi.
class _FormatBar extends StatelessWidget {
  const _FormatBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: cs.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.stateFormatsTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final f in const <String>['FLAC', 'WAV', 'MP3', 'M4A'])
                ...<Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        f,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  if (f != 'M4A') const SizedBox(width: 6),
                ],
            ],
          ),
        ],
      ),
    );
  }
}