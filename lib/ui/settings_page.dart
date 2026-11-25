import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/library_controller.dart';
import '../data/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final lib = context.read<LibraryController>();
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Control',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              secondary: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  s.blockNetwork ? Icons.lock : Icons.lock_open,
                  key: ValueKey(s.blockNetwork),
                  color: s.blockNetwork ? Colors.greenAccent : primary,
                ),
              ),
              title: const Text('Block internet access'),
              subtitle: const Text(
                  'Kill switch: no request leaves the app. Music keeps playing offline.'),
              value: s.blockNetwork,
              onChanged: s.setBlockNetwork,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default download quality',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SegmentedButton<QualityTier>(
                    segments: const [
                      ButtonSegment(value: QualityTier.low, label: Text('Low')),
                      ButtonSegment(
                          value: QualityTier.balanced, label: Text('Mid')),
                      ButtonSegment(value: QualityTier.high, label: Text('High')),
                    ],
                    selected: {s.quality},
                    onSelectionChanged: (v) => s.setQuality(v.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('Accent color',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < kAccents.length; i++)
                        GestureDetector(
                          onTap: () => s.setAccent(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kAccents[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: s.accentIndex == i
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Scan Music & Download folders'),
                  subtitle: const Text('Off = only show files downloaded here'),
                  value: s.scanShared,
                  onChanged: (v) async {
                    await s.setScanShared(v);
                    await lib.refresh();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Rescan library'),
                  onTap: lib.refresh,
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('App permissions'),
                  onTap: openAppSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('Delete all downloads'),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete all downloads?'),
                        content: const Text(
                            'Only files downloaded by Shafiq mode are removed.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) await lib.deleteAllDownloads();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Privacy\n'
                '• No accounts, analytics, ads or crash reporting.\n'
                '• Network is used only when you search or download.\n'
                '• No thumbnails are fetched, so no image servers see you.\n'
                '• Everything is stored on this device; backups are disabled.\n'
                '• For an OS-level block, use Android Settings → Apps → Shafiq mode → Mobile data & Wi-Fi.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
