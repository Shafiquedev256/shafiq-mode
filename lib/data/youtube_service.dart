import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../core/network_guard.dart';
import 'settings_controller.dart';

class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

class CancelToken {
  bool cancelled = false;
}

String sanitizeFileName(String input) {
  final s = input
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.isEmpty) return 'audio';
  return s.length > 120 ? s.substring(0, 120).trim() : s;
}

/// Streams sorted by bitrate ascending; prefers MP4/AAC (best compatibility).
List<AudioOnlyStreamInfo> sortedStreams(List<AudioOnlyStreamInfo> all) {
  final mp4 = all.where((s) => s.container == StreamContainer.mp4).toList();
  return [...(mp4.isNotEmpty ? mp4 : all)]..sort(
      (a, b) => a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
}

AudioOnlyStreamInfo pickStream(List<AudioOnlyStreamInfo> all, QualityTier t) {
  final s = sortedStreams(all);
  return switch (t) {
    QualityTier.low => s.first,
    QualityTier.balanced => s[s.length ~/ 2],
    QualityTier.high => s.last,
  };
}

String extensionFor(AudioOnlyStreamInfo s) =>
    s.container == StreamContainer.mp4 ? 'm4a' : s.container.name;

/// Only talks to YouTube through the [NetworkGuard]-wrapped client.
class YoutubeService {
  YoutubeService(NetworkGuard guard)
      : _yt = YoutubeExplode(YoutubeHttpClient(guard.createClient()));

  final YoutubeExplode _yt;

  Future<List<Video>> search(String query) async {
    final id = VideoId.parseVideoId(query);
    if (id != null) return [await _yt.videos.get(id)];
    return List<Video>.of(await _yt.search.search(query));
  }

  Future<List<AudioOnlyStreamInfo>> qualities(VideoId id) async {
    final manifest = await _yt.videos.streamsClient.getManifest(id);
    final all = manifest.audioOnly.toList();
    if (all.isEmpty) throw StateError('No audio streams available');
    return sortedStreams(all);
  }

  Future<File> download({
    required Video video,
    required AudioOnlyStreamInfo stream,
    required Directory dir,
    required CancelToken cancel,
    required void Function(double) onProgress,
  }) async {
    final base = sanitizeFileName(video.title);
    final ext = extensionFor(stream);
    var target = File(p.join(dir.path, '$base.$ext'));
    for (var i = 2; await target.exists(); i++) {
      target = File(p.join(dir.path, '$base ($i).$ext'));
    }
    final part = File('${target.path}.part');
    final sink = part.openWrite();
    var closed = false;
    try {
      final total = stream.size.totalBytes;
      var got = 0;
      await for (final chunk in _yt.videos.streamsClient.get(stream)) {
        if (cancel.cancelled) throw const DownloadCancelled();
        sink.add(chunk);
        got += chunk.length;
        onProgress(total == 0 ? 0 : got / total);
      }
      await sink.flush();
      await sink.close();
      closed = true;
      return await part.rename(target.path);
    } catch (_) {
      if (!closed) await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }
}
