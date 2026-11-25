import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'audio/player_controller.dart';
import 'core/network_guard.dart';
import 'data/download_controller.dart';
import 'data/library_controller.dart';
import 'data/settings_controller.dart';
import 'data/youtube_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.shafiq.shafiq_mode.audio',
    androidNotificationChannelName: 'Shafiq mode playback',
    androidNotificationOngoing: true,
  );
  final guard = NetworkGuard();
  final settings = await SettingsController.load(guard);
  final youtube = YoutubeService(guard);
  final library = LibraryController(settings);
  runApp(ShafiqApp(
    settings: settings,
    youtube: youtube,
    library: library,
    downloads: DownloadController(youtube, library),
    player: PlayerController(),
  ));
}
