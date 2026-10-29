import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/sleep_timer_sheet.dart';

/// Bildirim ve kilit ekranı — M3 tasarım güncellemesi.
///
/// Android 13+ medya bildirimi (MediaStyle) sistem tarafından çizilir;
/// bu sayfa o deneyimin UYGULAMA İÇİ CANLI ÖNİZLEMESİDİR ve tüm kontroller
/// gerçek PlayerController durumuna bağlıdır:
/// - Medya kartı: kapak, başlık/sanatçı/albüm, dalga biçimli ilerleme
///   çubuğu (dokununca gerçek konuma seek eder), oynat/duraklat, ileri/geri,
///   karıştır, favori, kuyruk
/// - Uyku zamanlayıcısı ikincil bildirim kartı: aktifken kalan süre ve
///   uzatma eylemi (gerçek SleepTimerController)
/// - Bildirim izni satırı: POST_NOTIFICATIONS durumu + uygulama ayarları
///
/// Tasarımdaki kilit ekranı saati/hava durumu, hızlı ayarlar karo kümeleri,
/// ses çıkışı değiştirici ve "Bit-Perfect / DAC" rozetleri EKLENMEDİ: bunlar
/// sistem kabuk ögeleridir ya da karşılığı olmayan donanım iddialarıdır.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _clockText {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsRowNotifications)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // --- Açıklama bandı ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.notifPreviewIntro,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Kilit ekranı saati ---
          Center(
            child: Column(
              children: [
                Text(
                  _clockText,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${_now.day.toString().padLeft(2, '0')}.${_now.month.toString().padLeft(2, '0')}.${_now.year}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Medya bildirimi kartı ---
          _MediaNotificationCard(),
          const SizedBox(height: 12),

          // --- Uyku zamanlayıcısı ikincil bildirimi ---
          _SleepNotificationCard(),
          const SizedBox(height: 16),

          // --- Bildirim izni satırı ---
          _PermissionRow(),
        ],
      ),
    );
  }
}

// ========== MEDYA BİLDİRİMİ KARTI ==========

class _MediaNotificationCard extends StatelessWidget {
  _MediaNotificationCard();

  final PlayerController _player = Get.find<PlayerController>();
  final FavoriteController _fav = Get.find<FavoriteController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Obx(() {
        final item = _player.currentItem.value;
        final song = _player.currentSong;
        final playing = _player.isPlaying.value;
        final canFav = song != null && song.id >= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uygulama kimliği satırı
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.graphic_eq, size: 14, color: cs.primary),
                ),
                const SizedBox(width: 7),
                Text(
                  l10n.appName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ' • ${l10n.nowPlaying}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kapak + künye + favori
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: ArtworkImage(
                    songId: song?.id,
                    borderRadius: BorderRadius.circular(16),
                    fallbackIcon: Icons.album,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.title ?? l10n.playerNoSong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item?.artist ?? l10n.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.secondary,
                        ),
                      ),
                      if ((item?.album ?? '').isNotEmpty)
                        Text(
                          item!.album!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (canFav)
                  Obx(() {
                    final isFav = _fav.isFavorite(song.id);
                    return IconButton(
                      tooltip: isFav
                          ? l10n.removeFromFavorites
                          : l10n.addToFavorites,
                      onPressed: () => _fav.toggle(song),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? cs.primary : cs.onSurfaceVariant,
                        size: 24,
                      ),
                    );
                  })
                else
                  const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 6),
            // Dalga biçimli ilerleme (dokun = seek)
            _SquiggleSeekBar(),
            // Kontroller
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: l10n.queueTitle,
                  onPressed: item == null
                      ? null
                      : () => Get.toNamed<void>(AppRoutes.queue),
                  icon: Icon(Icons.queue_music,
                      size: 24, color: cs.onSurfaceVariant),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.previousTrack,
                      onPressed: _player.previous,
                      icon: Icon(Icons.skip_previous,
                          size: 30, color: cs.onSurface),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: FilledButton(
                        onPressed: _player.togglePlayPause,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          size: 30,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.nextTrack,
                      onPressed: _player.next,
                      icon: Icon(Icons.skip_next,
                          size: 30, color: cs.onSurface),
                    ),
                  ],
                ),
                Obx(
                  () => IconButton(
                    tooltip: l10n.shuffleAll,
                    onPressed: _player.toggleShuffle,
                    icon: Icon(
                      Icons.shuffle,
                      size: 22,
                      color: _player.shuffleEnabled.value
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

// ========== DALGA İLERLEME ÇUBUĞU ==========

/// Android 13 tarzı dalgalı ilerleme: çalınan bölümde dalga, kalan bölümde
/// düz çizgi. Dokunma/sürükleme ile gerçek konuma seek eder.
class _SquiggleSeekBar extends StatefulWidget {
  _SquiggleSeekBar();

  final PlayerController _player = Get.find<PlayerController>();

  @override
  State<_SquiggleSeekBar> createState() => _SquiggleSeekBarState();
}

class _SquiggleSeekBarState extends State<_SquiggleSeekBar> {
  void _seekTo(double ratio, Duration duration) {
    if (duration.inMilliseconds <= 0) return;
    final ms = (ratio.clamp(0.0, 1.0) * duration.inMilliseconds).round();
    widget._player.seek(Duration(milliseconds: ms));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = widget._player;

    return Obx(() {
      final pos = player.position.value;
      final dur = player.duration.value;
      final totalMs = dur.inMilliseconds;
      final ratio =
          totalMs > 0 ? (pos.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final box = context.findRenderObject() as RenderBox;
          _seekTo(
            d.localPosition.dx / box.size.width,
            dur,
          );
        },
        onHorizontalDragUpdate: (d) {
          final box = context.findRenderObject() as RenderBox;
          _seekTo(
            d.localPosition.dx / box.size.width,
            dur,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SizedBox(
                height: 22,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SquigglePainter(
                    progress: ratio,
                    playedColor: cs.primary,
                    trackColor: cs.surfaceContainerHighest,
                    thumbColor: cs.primary,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    pos.clock,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dur.clock,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SquigglePainter extends CustomPainter {
  const _SquigglePainter({
    required this.progress,
    required this.playedColor,
    required this.trackColor,
    required this.thumbColor,
  });

  final double progress;
  final Color playedColor;
  final Color trackColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final playedWidth = size.width * progress;
    const amp = 4.5;
    const waveLen = 16.0;

    // Kalan düz çizgi
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(playedWidth, midY),
      Offset(size.width, midY),
      track,
    );

    // Çalınan dalga bölümü
    final wave = Paint()
      ..color = playedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, midY);
    var x = 0.0;
    var up = true;
    while (x < playedWidth) {
      final next = math.min(x + waveLen / 2, playedWidth);
      path.quadraticBezierTo(
        (x + next) / 2,
        up ? midY - amp : midY + amp,
        next,
        midY,
      );
      up = !up;
      x = next;
    }
    canvas.drawPath(path, wave);

    // İmleç
    if (progress > 0) {
      canvas.drawCircle(Offset(playedWidth, midY), 6.5,
          Paint()..color = thumbColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SquigglePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ========== UYKU ZAMANLAYICISI BİLDİRİM KARTI ==========

class _SleepNotificationCard extends StatelessWidget {
  _SleepNotificationCard();

  final SleepTimerController _ctrl = Get.find<SleepTimerController>();

  String _mmss(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final active = _ctrl.isActive.value;
      final endOfTrack = _ctrl.isEndOfTrackMode.value;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bedtime,
              size: 20,
              color: active ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active
                        ? (endOfTrack
                            ? l10n.sleepTimerEndOfTrackSet
                            : l10n.notifSleepActive)
                        : l10n.sleepTimerOff,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    active
                        ? (endOfTrack
                            ? l10n.sleepTimerEndOfTrackDesc
                            : l10n.notifSleepFadesIn(
                                _mmss(_ctrl.remainingSeconds.value)))
                        : l10n.notifSleepHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (active) ...<Widget>[
              TextButton(
                onPressed: () =>
                    _ctrl.startTimer((_ctrl.remainingSeconds.value / 60)
                            .ceil() +
                        5),
                child: Text(l10n.sleepTimerAddFive),
              ),
              IconButton(
                tooltip: l10n.sleepStopAction,
                onPressed: _ctrl.cancelTimer,
                icon: Icon(Icons.stop_circle, color: cs.error),
              ),
            ] else
              FilledButton.tonal(
                onPressed: () => SleepTimerSheet.show(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                child: Text(l10n.sleepTimer),
              ),
          ],
        ),
      );
    });
  }
}

// ========== BİLDİRİM İZNİ SATIRI ==========

class _PermissionRow extends StatelessWidget {
  _PermissionRow();

  final PermissionController _perm = Get.find<PermissionController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.permissionNotificationTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.notifPermissionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _perm.openSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(l10n.permissionOpenSettingsButton),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
