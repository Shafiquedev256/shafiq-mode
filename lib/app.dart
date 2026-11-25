import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio/player_controller.dart';
import 'core/theme.dart';
import 'data/download_controller.dart';
import 'data/library_controller.dart';
import 'data/settings_controller.dart';
import 'data/youtube_service.dart';
import 'ui/home_shell.dart';

class ShafiqApp extends StatelessWidget {
  const ShafiqApp({
    super.key,
    required this.settings,
    required this.youtube,
    required this.library,
    required this.downloads,
    required this.player,
  });

  final SettingsController settings;
  final YoutubeService youtube;
  final LibraryController library;
  final DownloadController downloads;
  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: library),
        ChangeNotifierProvider.value(value: downloads),
        ChangeNotifierProvider.value(value: player),
        Provider.value(value: youtube),
      ],
      child: Consumer<SettingsController>(
        builder: (_, s, __) => MaterialApp(
          title: 'Shafiq mode',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(kAccents[s.accentIndex]),
          home: const HomeShell(),
        ),
      ),
    );
  }
}
