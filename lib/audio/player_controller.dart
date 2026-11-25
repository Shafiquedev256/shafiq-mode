import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/track.dart';

/// Wraps just_audio. Background/lock-screen playback is provided by
/// just_audio_background (foreground media service + notification controls).
class PlayerController extends ChangeNotifier {
  PlayerController() {
    player.currentIndexStream.listen((_) => notifyListeners());
    player.playerStateStream.listen((_) => notifyListeners());
    player.playbackEventStream.listen((_) {}, onError: (Object e, _) async {
      lastError = 'Skipped a file this device cannot decode.';
      notifyListeners();
      if (player.hasNext) {
        await player.seekToNext();
        await player.play();
      }
    });
  }

  final player = AudioPlayer();
  List<Track> _queue = const [];
  String? lastError;
  Timer? _sleep;
  DateTime? sleepEndsAt;

  Track? get current {
    final i = player.currentIndex;
    return (i == null || i >= _queue.length) ? null : _queue[i];
  }

  bool get playing => player.playing;

  Future<void> playQueue(List<Track> tracks, int start,
      {bool shuffle = false}) async {
    if (tracks.isEmpty) return;
    lastError = null;
    _queue = tracks;
    await player.setShuffleModeEnabled(shuffle);
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          for (final t in tracks)
            AudioSource.uri(
              Uri.file(t.path),
              tag: MediaItem(
                id: t.id,
                title: t.title,
                artist: t.artist,
                duration: t.duration,
              ),
            ),
        ],
      ),
      initialIndex: start,
    );
    if (shuffle) await player.shuffle();
    unawaited(player.play());
  }

  Future<void> toggle() => player.playing ? player.pause() : player.play();

  Future<void> toggleShuffle() async {
    await player.setShuffleModeEnabled(!player.shuffleModeEnabled);
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    final next = switch (player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await player.setLoopMode(next);
    notifyListeners();
  }

  Future<void> setSpeed(double s) async {
    await player.setSpeed(s);
    notifyListeners();
  }

  void setSleepTimer(Duration? d) {
    _sleep?.cancel();
    sleepEndsAt = d == null ? null : DateTime.now().add(d);
    _sleep = d == null
        ? null
        : Timer(d, () {
            player.pause();
            sleepEndsAt = null;
            notifyListeners();
          });
    notifyListeners();
  }

  @override
  void dispose() {
    _sleep?.cancel();
    player.dispose();
    super.dispose();
  }
}
