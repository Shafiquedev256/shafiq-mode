import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings_controller.dart';
import 'track.dart';

enum SortMode { title, artist, recent }

/// Scans the device for audio and owns the downloaded-track index.
class LibraryController extends ChangeNotifier {
  LibraryController(this._settings);

  static const _sharedDirs = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
  ];

  final SettingsController _settings;
  List<Track> _tracks = const [];
  bool loading = false;
  bool permissionDenied = false;

  List<Track> get tracks => _tracks;

  List<Track> filtered(String query, SortMode sort) {
    final q = query.trim().toLowerCase();
    final list = _tracks
        .where((t) =>
            q.isEmpty ||
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q))
        .toList();
    list.sort(switch (sort) {
      SortMode.title => (a, b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      SortMode.artist => (a, b) =>
          a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      SortMode.recent => (a, b) => b.addedMs.compareTo(a.addedMs),
    });
    return list;
  }

  Future<Directory> downloadsDir() async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'Shafiq mode')).create(recursive: true);
  }

  Future<File> _indexFile() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'index.json'));

  Future<Map<String, dynamic>> _readIndex() async {
    try {
      final f = await _indexFile();
      if (await f.exists()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Index unreadable, starting fresh: $e');
    }
    return {};
  }

  Future<void> _writeIndex(Map<String, dynamic> index) async =>
      (await _indexFile()).writeAsString(jsonEncode(index));

  Future<bool> _ensurePermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.audio.request().isGranted) return true;
    return Permission.storage.request().isGranted;
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    final index = await _readIndex();
    final dl = await downloadsDir();
    final dirs = <Directory>[dl];
    permissionDenied = false;
    if (_settings.scanShared) {
      if (await _ensurePermission()) {
        dirs.addAll(_sharedDirs.map(Directory.new));
      } else {
        permissionDenied = true;
      }
    }
    final found = <String, Track>{};
    for (final dir in dirs) {
      if (!await dir.exists()) continue;
      try {
        await for (final e in dir.list(recursive: true, followLinks: false)) {
          if (e is! File || !kAudioExtensions.contains(p.extension(e.path).toLowerCase())) {
            continue;
          }
          final meta = index[e.path] as Map<String, dynamic>?;
          found[e.path] = Track.fromFile(
            e.path,
            title: meta?['title'] as String?,
            artist: meta?['artist'] as String?,
            durationMs: meta?['durationMs'] as int?,
            addedMs: (await e.lastModified()).millisecondsSinceEpoch,
            downloaded: p.isWithin(dl.path, e.path),
          );
        }
      } on FileSystemException catch (e) {
        debugPrint('Skipping ${dir.path}: $e');
      }
    }
    _tracks = found.values.toList();
    loading = false;
    notifyListeners();
  }

  Future<void> addDownloaded(
    File file, {
    required String title,
    required String artist,
    int? durationMs,
  }) async {
    final index = await _readIndex();
    index[file.path] = {
      'title': title,
      'artist': artist,
      'durationMs': durationMs,
    };
    await _writeIndex(index);
    _tracks = [
      ..._tracks.where((t) => t.id != file.path),
      Track.fromFile(
        file.path,
        title: title,
        artist: artist,
        durationMs: durationMs,
        addedMs: DateTime.now().millisecondsSinceEpoch,
        downloaded: true,
      ),
    ];
    notifyListeners();
  }

  Future<void> deleteTrack(Track t) async {
    if (!t.downloaded) return; // never touch files we did not create
    final f = File(t.path);
    if (await f.exists()) await f.delete();
    final index = await _readIndex()
      ..remove(t.path);
    await _writeIndex(index);
    _tracks = _tracks.where((x) => x.id != t.id).toList();
    notifyListeners();
  }

  Future<void> deleteAllDownloads() async {
    for (final t in _tracks.where((t) => t.downloaded).toList()) {
      await deleteTrack(t);
    }
  }
}
