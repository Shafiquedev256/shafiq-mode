import 'package:flutter_test/flutter_test.dart';
import 'package:shafiq_mode/core/network_guard.dart';
import 'package:shafiq_mode/data/track.dart';
import 'package:shafiq_mode/data/youtube_service.dart';

void main() {
  test('sanitizeFileName strips illegal characters', () {
    expect(sanitizeFileName('a/b:c*?"<>|d'), 'abcd');
    expect(sanitizeFileName('///'), 'audio');
    expect(sanitizeFileName('x' * 200).length, 120);
  });

  test('Track.fromFile parses "Artist - Title"', () {
    final t = Track.fromFile('/m/Daft Punk - One More Time.mp3');
    expect(t.artist, 'Daft Punk');
    expect(t.title, 'One More Time');
    expect(Track.fromFile('/m/solo.mp3').artist, 'Unknown artist');
  });

  test('NetworkGuard blocks requests when enabled', () async {
    final guard = NetworkGuard()..blocked = true;
    final client = guard.createClient();
    expect(
      () => client.get(Uri.parse('https://example.com')),
      throwsA(isA<NetworkBlockedException>()),
    );
  });

  test('scan list covers common formats', () {
    for (final e in ['.mp3', '.flac', '.wav', '.ogg', '.opus', '.m4a', '.mka', '.mid']) {
      expect(kAudioExtensions, contains(e));
    }
  });
}
