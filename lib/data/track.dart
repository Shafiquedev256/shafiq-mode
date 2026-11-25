import 'package:path/path.dart' as p;

/// Formats Android's native decoders (via ExoPlayer) can play.
const kAudioExtensions = <String>{
  '.mp3', '.m4a', '.m4b', '.aac', '.adts', '.flac', '.wav', '.wave',
  '.ogg', '.oga', '.opus', '.webm', '.weba', '.mka', '.amr', '.awb',
  '.3gp', '.mid', '.midi', '.ac3', '.eac3',
};

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    this.durationMs,
    this.addedMs = 0,
    this.downloaded = false,
  });

  /// File path doubles as the unique id.
  final String id;
  final String title;
  final String artist;
  final String path;
  final int? durationMs;
  final int addedMs;
  final bool downloaded;

  Duration? get duration =>
      durationMs == null ? null : Duration(milliseconds: durationMs!);

  /// Derives title/artist from a file name like "Artist - Title.mp3".
  factory Track.fromFile(
    String path, {
    String? title,
    String? artist,
    int? durationMs,
    int addedMs = 0,
    bool downloaded = false,
  }) {
    final name = p.basenameWithoutExtension(path);
    var a = artist ?? 'Unknown artist';
    var t = title ?? name;
    if (title == null && name.contains(' - ')) {
      final i = name.indexOf(' - ');
      a = artist ?? name.substring(0, i).trim();
      t = name.substring(i + 3).trim();
    }
    return Track(
      id: path,
      title: t,
      artist: a,
      path: path,
      durationMs: durationMs,
      addedMs: addedMs,
      downloaded: downloaded,
    );
  }
}
