import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/download_controller.dart';
import '../data/library_controller.dart';
import 'discover_page.dart';
import 'downloads_page.dart';
import 'library_page.dart';
import 'settings_page.dart';
import 'widgets/mini_player.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<LibraryController>().refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = context.select<DownloadController, int>((d) => d.activeCount);
    const pages = [
      LibraryPage(),
      DiscoverPage(),
      DownloadsPage(),
      SettingsPage(),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              const NavigationDestination(
                icon: Icon(Icons.travel_explore_outlined),
                selectedIcon: Icon(Icons.travel_explore),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: active > 0,
                  label: Text('$active'),
                  child: const Icon(Icons.download_outlined),
                ),
                selectedIcon: const Icon(Icons.download),
                label: 'Downloads',
              ),
              const NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Control',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
