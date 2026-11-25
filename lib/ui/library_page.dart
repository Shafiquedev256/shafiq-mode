import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../audio/player_controller.dart';
import '../data/library_controller.dart';
import '../data/track.dart';
import 'widgets/common.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _query = '';
  SortMode _sort = SortMode.recent;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    final pc = context.watch<PlayerController>();
    final tracks = lib.filtered(_query, _sort);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Shafiq mode',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Rescan',
              icon: const Icon(Icons.refresh),
              onPressed: lib.refresh,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search your music',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: tracks.isEmpty
                            ? null
                            : () => pc.playQueue(tracks, 0),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: tracks.isEmpty
                            ? null
                            : () => pc.playQueue(
                                  tracks,
                                  Random().nextInt(tracks.length),
                                  shuffle: true,
                                ),
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Shuffle'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<SortMode>(
                      icon: const Icon(Icons.sort),
                      initialValue: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: SortMode.recent, child: Text('Recently added')),
                        PopupMenuItem(
                            value: SortMode.title, child: Text('Title')),
                        PopupMenuItem(
                            value: SortMode.artist, child: Text('Artist')),
                      ],
                    ),
                  ],
                ),
                if (lib.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (lib.permissionDenied)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder_off_outlined),
                        title: const Text('Audio access denied'),
                        subtitle: const Text(
                            'Only app downloads are shown. Grant access to see all music.'),
                        trailing: TextButton(
                          onPressed: openAppSettings,
                          child: const Text('Allow'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (tracks.isEmpty && !lib.loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No music yet.\nDownload something in Discover or add files to your Music folder.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (_, i) => _TrackTile(
              track: tracks[i],
              onTap: () => pc.playQueue(tracks, i),
            )
                .animate()
                .fadeIn(delay: (25 * min(i, 10)).ms, duration: 300.ms)
                .slideX(begin: .04, curve: Curves.easeOut),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.onTap});
  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<PlayerController>();
    final isCurrent = pc.current?.id == track.id;
    return ListTile(
      onTap: onTap,
      leading: TrackAvatar(
        seed: track.title,
        overlay: isCurrent ? EqualizerBars(active: pc.playing) : null,
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: track.downloaded
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (_) => context.read<LibraryController>().deleteTrack(track),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'del', child: Text('Delete from device')),
              ],
            )
          : null,
    );
  }
}
