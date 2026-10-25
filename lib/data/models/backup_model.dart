class BackupSong {
  final String uri;
  final String path;
  final String title;
  final String? artist;
  final int durationMs;

  const BackupSong({
    required this.uri,
    required this.path,
    required this.title,
    this.artist,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'path': path,
        'title': title,
        'artist': artist,
        'durationMs': durationMs,
      };

  factory BackupSong.fromJson(Map<String, dynamic> json) => BackupSong(
        uri: json['uri'] as String? ?? '',
        path: json['path'] as String? ?? '',
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String?,
        durationMs: json['durationMs'] as int? ?? 0,
      );
}

class BackupPlaylist {
  final String name;
  final List<BackupSong> songs;

  const BackupPlaylist({required this.name, required this.songs});

  Map<String, dynamic> toJson() => {
        'name': name,
        'songs': songs.map((s) => s.toJson()).toList(),
      };

  factory BackupPlaylist.fromJson(Map<String, dynamic> json) => BackupPlaylist(
        name: json['name'] as String? ?? 'Playlist',
        songs: (json['songs'] as List<dynamic>?)
                ?.map((e) => BackupSong.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class BackupTheme {
  final String name;
  final String settingsJson;
  const BackupTheme({required this.name, required this.settingsJson});
  Map<String, dynamic> toJson() => {'name': name, 'settingsJson': settingsJson};
  factory BackupTheme.fromJson(Map<String, dynamic> json) =>
      BackupTheme(name: json['name'] ?? 'Theme', settingsJson: json['settingsJson'] ?? '{}');
}

class BackupEqualizerPreset {
  final String name;
  final String bandsJson;
  const BackupEqualizerPreset({required this.name, required this.bandsJson});
  Map<String, dynamic> toJson() => {'name': name, 'bandsJson': bandsJson};
  factory BackupEqualizerPreset.fromJson(Map<String, dynamic> json) =>
      BackupEqualizerPreset(name: json['name'] ?? 'Preset', bandsJson: json['bandsJson'] ?? '[]');
}

class BackupModel {
  final int version;
  final List<BackupPlaylist> playlists;
  final List<BackupSong> favorites;
  final List<BackupTheme> customThemes;
  final List<BackupEqualizerPreset> equalizerPresets;
  final Map<String, dynamic> settings;

  const BackupModel({
    this.version = 1,
    required this.playlists,
    required this.favorites,
    required this.customThemes,
    required this.equalizerPresets,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'playlists': playlists.map((p) => p.toJson()).toList(),
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'customThemes': customThemes.map((t) => t.toJson()).toList(),
        'equalizerPresets': equalizerPresets.map((e) => e.toJson()).toList(),
        'settings': settings,
      };

  factory BackupModel.fromJson(Map<String, dynamic> json) => BackupModel(
        version: json['version'] as int? ?? 1,
        playlists: (json['playlists'] as List<dynamic>?)
                ?.map((e) => BackupPlaylist.fromJson(e))
                .toList() ?? [],
        favorites: (json['favorites'] as List<dynamic>?)
                ?.map((e) => BackupSong.fromJson(e))
                .toList() ?? [],
        customThemes: (json['customThemes'] as List<dynamic>?)
                ?.map((e) => BackupTheme.fromJson(e))
                .toList() ?? [],
        equalizerPresets: (json['equalizerPresets'] as List<dynamic>?)
                ?.map((e) => BackupEqualizerPreset.fromJson(e))
                .toList() ?? [],
        settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      );
}