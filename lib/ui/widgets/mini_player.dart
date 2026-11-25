import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../audio/player_controller.dart';
import '../now_playing_page.dart';
import 'common.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<PlayerController>();
    final t = pc.current;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: t == null
          ? const SizedBox(width: double.infinity)
          : GestureDetector(
              onTap: () => Navigator.of(context).push(NowPlayingPage.route()),
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B2B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Hero(
                        tag: 'art',
                        child: TrackAvatar(seed: t.title, size: 42),
                      ),
                      title: Text(t.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(t.artist,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                pc.playing ? Icons.pause : Icons.play_arrow,
                                key: ValueKey(pc.playing),
                              ),
                            ),
                            onPressed: pc.toggle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: pc.player.seekToNext,
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<Duration>(
                      stream: pc.player.positionStream,
                      builder: (_, snap) {
                        final total = pc.player.duration?.inMilliseconds ?? 0;
                        final v = total == 0
                            ? 0.0
                            : (snap.data?.inMilliseconds ?? 0) / total;
                        return LinearProgressIndicator(
                          value: v.clamp(0.0, 1.0),
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
